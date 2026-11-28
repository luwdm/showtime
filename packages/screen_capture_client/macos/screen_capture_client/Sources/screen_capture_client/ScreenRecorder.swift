import AVFoundation
import ScreenCaptureKit

/// Writes the frames of an `SCStream` into an MP4 file.
final class ScreenRecorder: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
  /// Called when the system stops the stream, e.g. because the captured window
  /// was closed. The path is set if a playable file was written.
  var onInterrupted: ((_ path: String?, _ message: String) -> Void)?

  private let outputURL: URL
  private let writer: AVAssetWriter
  private let input: AVAssetWriterInput
  private let queue = DispatchQueue(label: "io.github.luwdm.showtime.screen-recorder")
  private var stream: SCStream!

  // Only accessed on `queue`.
  private var sessionStarted = false
  private var lastPresentationTime: CMTime = .invalid
  private var isFinishing = false
  private var finishTask: Task<URL, Error>?

  init(filter: SCContentFilter, configuration: SCStreamConfiguration, outputURL: URL) throws {
    self.outputURL = outputURL
    if FileManager.default.fileExists(atPath: outputURL.path) {
      try FileManager.default.removeItem(at: outputURL)
    }
    writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
    input = AVAssetWriterInput(
      mediaType: .video,
      outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: configuration.width,
        AVVideoHeightKey: configuration.height,
      ]
    )
    input.expectsMediaDataInRealTime = true
    guard writer.canAdd(input) else {
      throw PigeonError(code: "writer-failed", message: "Cannot configure the video writer.", details: nil)
    }
    writer.add(input)
    super.init()
    stream = SCStream(filter: filter, configuration: configuration, delegate: self)
  }

  func start() async throws {
    try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)
    guard writer.startWriting() else {
      throw PigeonError(
        code: "writer-failed",
        message: writer.error?.localizedDescription ?? "Cannot start writing.",
        details: nil
      )
    }
    do {
      try await stream.startCapture()
    } catch {
      writer.cancelWriting()
      throw PigeonError(code: "capture-failed", message: error.localizedDescription, details: nil)
    }
  }

  func stop() async throws -> URL {
    try? await stream.stopCapture()
    return try await finish()
  }

  // MARK: - SCStreamOutput

  func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
    guard type == .screen, sampleBuffer.isValid, !isFinishing, isCompleteFrame(sampleBuffer) else { return }

    let time = sampleBuffer.presentationTimeStamp
    if !sessionStarted {
      writer.startSession(atSourceTime: time)
      sessionStarted = true
    }
    if input.isReadyForMoreMediaData, input.append(sampleBuffer) {
      lastPresentationTime = time
    }
  }

  // MARK: - SCStreamDelegate

  func stream(_ stream: SCStream, didStopWithError error: Error) {
    Task {
      let url = try? await finish()
      onInterrupted?(url?.path, error.localizedDescription)
    }
  }

  // MARK: - Helpers

  /// Finishes the file. Safe to call more than once.
  private func finish() async throws -> URL {
    let task: Task<URL, Error> = queue.sync {
      if let finishTask { return finishTask }
      isFinishing = true
      let hasFrames = sessionStarted
      let task = Task { try await self.finishWriting(hasFrames: hasFrames) }
      finishTask = task
      return task
    }
    return try await task.value
  }

  private func finishWriting(hasFrames: Bool) async throws -> URL {
    guard hasFrames else {
      writer.cancelWriting()
      throw PigeonError(code: "no-frames", message: "No frames were captured.", details: nil)
    }

    input.markAsFinished()
    let endTime = queue.sync { lastPresentationTime }
    if endTime.isValid {
      writer.endSession(atSourceTime: endTime)
    }
    await writer.finishWriting()

    guard writer.status == .completed else {
      throw PigeonError(
        code: "writer-failed",
        message: writer.error?.localizedDescription ?? "Writing the video failed.",
        details: nil
      )
    }
    return outputURL
  }

  /// ScreenCaptureKit also delivers idle and blank frames without image data.
  private func isCompleteFrame(_ sampleBuffer: CMSampleBuffer) -> Bool {
    guard
      let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false)
        as? [[SCStreamFrameInfo: Any]],
      let rawStatus = attachments.first?[.status] as? Int,
      let status = SCFrameStatus(rawValue: rawStatus)
    else { return false }
    return status == .complete
  }
}
