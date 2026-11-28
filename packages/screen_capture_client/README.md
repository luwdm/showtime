# screen_capture_client

Data-Schicht von Showtime: nimmt den Bildschirm mit den nativen APIs der Plattform auf.

| Plattform | Umsetzung |
|---|---|
| macOS 13+ | ScreenCaptureKit + AVAssetWriter (H.264/MP4) |
| Windows, Linux | noch nicht umgesetzt, siehe [Recherche](../../docs/screen-capture-platforms.md) |

## Verwendung

```dart
final client = ScreenCaptureClient();

if (!await client.hasPermission()) await client.requestPermission();

final displays = await client.getDisplays();
await client.startRecording(
  source: DisplayCaptureSource(displayId: displays.first.id),
  outputPath: '/path/to/video.mp4',
);
final path = await client.stopRecording();
```

## Schnittstelle zur Plattform

Die Nachrichten zwischen Dart und Swift werden mit [Pigeon](https://pub.dev/packages/pigeon) aus `pigeon/messages.dart` generiert. Nach Änderungen:

```bash
fvm dart run pigeon --input pigeon/messages.dart
```
