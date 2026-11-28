import Cocoa
import FlutterMacOS
import ScreenCaptureKit

/// Flutter plugin that records the screen with ScreenCaptureKit.
public class ScreenCaptureClientPlugin: NSObject, FlutterPlugin, ScreenCaptureHostApi {
  private let flutterApi: ScreenCaptureFlutterApi
  private var recorder: ScreenRecorder?

  init(flutterApi: ScreenCaptureFlutterApi) {
    self.flutterApi = flutterApi
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = ScreenCaptureClientPlugin(
      flutterApi: ScreenCaptureFlutterApi(binaryMessenger: registrar.messenger)
    )
    ScreenCaptureHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  // MARK: - Permission

  func hasPermission() throws -> Bool {
    CGPreflightScreenCaptureAccess()
  }

  func requestPermission() throws -> Bool {
    CGRequestScreenCaptureAccess()
  }

  func openPermissionSettings() throws {
    let url = URL(
      string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
    )!
    NSWorkspace.shared.open(url)
  }

  // MARK: - Files

  func getDefaultOutputDirectory() throws -> String {
    // With the `com.apple.security.assets.movies.read-write` entitlement the
    // sandbox container's Movies folder links to the user's Movies folder.
    let movies = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0]
    return movies.appendingPathComponent("Showtime", isDirectory: true).path
  }

  func revealFile(path: String) throws {
    let url = URL(fileURLWithPath: path).resolvingSymlinksInPath()
    NSWorkspace.shared.activateFileViewerSelecting([url])
  }

  // MARK: - Sources

  func getDisplays() async throws -> [DisplayMessage] {
    let content = try await shareableContent()
    return content.displays.map {
      DisplayMessage(id: Int64($0.displayID), width: Double($0.width), height: Double($0.height))
    }
  }

  func getWindows() async throws -> [WindowMessage] {
    let content = try await shareableContent()
    return content.windows
      .filter { $0.windowLayer == 0 }
      .map {
        WindowMessage(
          id: Int64($0.windowID),
          title: $0.title,
          applicationName: $0.owningApplication?.applicationName,
          bundleIdentifier: $0.owningApplication?.bundleIdentifier,
          width: Double($0.frame.width),
          height: Double($0.frame.height),
          isOnScreen: $0.isOnScreen
        )
      }
  }

  // MARK: - Recording

  func startRecording(source: CaptureSourceMessage, options: RecordingOptionsMessage) async throws {
    guard recorder == nil else {
      throw PigeonError(code: "already-recording", message: "A recording is already running.", details: nil)
    }
    guard CGPreflightScreenCaptureAccess() else {
      throw PigeonError(code: "permission-denied", message: "Screen capture permission is missing.", details: nil)
    }

    let content = try await shareableContent()
    let (filter, size) = try makeFilter(source: source, content: content)

    let configuration = SCStreamConfiguration()
    configuration.width = size.width
    configuration.height = size.height
    configuration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(max(options.framesPerSecond, 1)))
    configuration.showsCursor = options.showsCursor
    configuration.queueDepth = 6
    if source.type == .display, let region = source.region {
      configuration.sourceRect = CGRect(x: region.x, y: region.y, width: region.width, height: region.height)
    }

    let outputURL = URL(fileURLWithPath: options.outputPath)
    try FileManager.default.createDirectory(
      at: outputURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )

    let recorder = try ScreenRecorder(
      filter: filter,
      configuration: configuration,
      outputURL: outputURL
    )
    recorder.onInterrupted = { [weak self] path, message in
      Task { @MainActor in
        guard let self else { return }
        self.recorder = nil
        try? await self.flutterApi.onRecordingInterrupted(path: path, message: message)
      }
    }
    try await recorder.start()
    self.recorder = recorder
  }

  func stopRecording() async throws -> String {
    guard let recorder else {
      throw PigeonError(code: "not-recording", message: "No recording is running.", details: nil)
    }
    self.recorder = nil
    return try await recorder.stop().path
  }

  // MARK: - Helpers

  private func shareableContent() async throws -> SCShareableContent {
    do {
      return try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    } catch {
      throw PigeonError(code: "content-unavailable", message: error.localizedDescription, details: nil)
    }
  }

  private func makeFilter(
    source: CaptureSourceMessage,
    content: SCShareableContent
  ) throws -> (SCContentFilter, (width: Int, height: Int)) {
    let scale = NSScreen.screens.map(\.backingScaleFactor).max() ?? 2

    switch source.type {
    case .display:
      guard let display = content.displays.first(where: { Int64($0.displayID) == source.id }) else {
        throw PigeonError(code: "source-not-found", message: "Display \(source.id) not found.", details: nil)
      }
      // Do not record Showtime's own windows.
      let ownApps = content.applications.filter { $0.processID == ProcessInfo.processInfo.processIdentifier }
      let filter = SCContentFilter(display: display, excludingApplications: ownApps, exceptingWindows: [])
      let points = source.region.map { CGSize(width: $0.width, height: $0.height) }
        ?? CGSize(width: display.width, height: display.height)
      return (filter, pixelSize(points, scale: scale))

    case .window:
      guard let window = content.windows.first(where: { Int64($0.windowID) == source.id }) else {
        throw PigeonError(code: "source-not-found", message: "Window \(source.id) not found.", details: nil)
      }
      let filter = SCContentFilter(desktopIndependentWindow: window)
      return (filter, pixelSize(window.frame.size, scale: scale))
    }
  }

  /// H.264 needs even dimensions.
  private func pixelSize(_ points: CGSize, scale: CGFloat) -> (width: Int, height: Int) {
    func even(_ value: CGFloat) -> Int { max(2, Int(value * scale) / 2 * 2) }
    return (even(points.width), even(points.height))
  }
}
