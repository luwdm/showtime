# Bildschirmaufnahme: Plattform-Recherche

Stand: November 2026. Grundlage für die Umsetzung von Windows und Linux nach dem macOS-Prototyp (#3).

Alle Plattformen werden hinter derselben Dart-API in `packages/screen_capture_client` (Pigeon) umgesetzt. Repository- und Feature-Schicht bleiben unverändert.

## macOS (umgesetzt)

- **API:** ScreenCaptureKit (`SCShareableContent`, `SCStream`), ab macOS 12.3; Showtime setzt macOS 13 voraus.
- **Kodierung:** `AVAssetWriter` mit H.264 in MP4. Ab macOS 15 gäbe es `SCRecordingOutput`, das wir für ältere Versionen aber nicht nutzen können.
- **Berechtigung:** „Bildschirm- & Systemaudioaufnahme" in den Systemeinstellungen. `CGRequestScreenCaptureAccess()` zeigt den Systemdialog nur einmal. Nach dem Erteilen muss die App neu gestartet werden.
- **Sandbox:** Aufnahme funktioniert in der App-Sandbox. Zum Speichern in `~/Movies` braucht es das Entitlement `com.apple.security.assets.movies.read-write`.
- **Cursor:** `SCStreamConfiguration.showsCursor` blendet den Systemcursor aus. Das brauchen wir später für das eigene Cursor-Rendering (#4, #7).

## Windows

- **API:** [Windows.Graphics.Capture](https://learn.microsoft.com/windows/uwp/audio-video-camera/screen-capture) (WinRT), ab Windows 10 1803. Bildschirme über `GraphicsCaptureItem` aus `HMONITOR`, Fenster aus `HWND` (`IGraphicsCaptureItemInterop`), ohne System-Picker.
- **Frames:** `Direct3D11CaptureFramePool` liefert D3D11-Texturen.
- **Kodierung:** Media Foundation (`IMFSinkWriter`) mit H.264-Hardware-Encoder, alternativ `Windows.Media.Transcoding`.
- **Cursor:** `GraphicsCaptureSession.IsCursorCaptureEnabled` (Windows 10 2004+).
- **Gelber Rahmen:** Ab Windows 11 per `IsBorderRequired = false` abschaltbar (braucht die Capability `graphicsCaptureWithoutBorder`).
- **Berechtigung:** Für Desktop-Apps keine Nutzerfreigabe nötig.
- **Umsetzung:** C++-Plugin (Flutter-Windows-Template) mit C++/WinRT.

## Linux

- **Wayland (Standard bei GNOME/KDE):** Bildschirmaufnahme nur über das [xdg-desktop-portal ScreenCast](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.ScreenCast.html) und PipeWire.
  - Der Nutzer wählt Bildschirm/Fenster immer im **System-Dialog des Portals**. Eine eigene Quellenliste wie auf macOS ist nicht möglich.
  - Mit `persist_mode` kann die Auswahl für spätere Sitzungen gespeichert werden.
  - Cursor: `cursor_mode` (versteckt, eingebettet oder als Metadaten). Die Metadaten-Variante ist ideal für eigenes Cursor-Rendering.
  - Frames per PipeWire-Stream, Kodierung z. B. mit GStreamer (`pipewiresrc ! x264enc ! mp4mux`).
- **X11:** Direkter Zugriff über XComposite/XShm oder GStreamer `ximagesrc`. Fensterliste ist möglich.
- **Umsetzung:** C-Plugin (GTK) mit GStreamer. Für Wayland braucht die Dart-API einen Weg, die Quelle über das Portal auswählen zu lassen, z. B. `pickSource()` statt `getDisplays()`/`getWindows()`.

## Folgen für die API

- `getDisplays()`/`getWindows()` sind auf Wayland nicht umsetzbar. Die Repository-Schicht sollte später zwischen „Quellen auflisten" und „Quelle vom System wählen lassen" unterscheiden können.
- Fortschritt und Fehler laufen bereits über `ScreenCaptureFlutterApi.onRecordingInterrupted`. Das passt für alle drei Plattformen.
