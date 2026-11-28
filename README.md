# Showtime

[![CI](https://github.com/luwdm/showtime/actions/workflows/ci.yaml/badge.svg)](https://github.com/luwdm/showtime/actions/workflows/ci.yaml)

Open-Source-Bildschirmrekorder für ansprechende Entwickler-Demos: Aufnahme mit automatischem Zoom, geglättetem Cursor, Hintergründen und Export als MP4/GIF.

Plattformen: macOS 13+ (Aufnahme), Windows und Linux folgen (siehe [Plattform-Recherche](docs/screen-capture-platforms.md)).

## Setup

Die Flutter-Version ist über [fvm](https://fvm.app) in `.fvmrc` gepinnt.

1. fvm installieren (siehe [Installationsanleitung](https://fvm.app/documentation/getting-started/installation))
2. Gepinnte Flutter-Version installieren:

   ```bash
   fvm install
   ```

3. Abhängigkeiten laden:

   ```bash
   fvm flutter pub get
   ```

4. App starten:

   ```bash
   fvm flutter run -d macos
   ```

5. Beim ersten Start die Bildschirmaufnahme erlauben (Systemeinstellungen › Datenschutz & Sicherheit › Bildschirm- & Systemaudioaufnahme) und Showtime danach neu starten.

Aufnahmen landen in `~/Movies/Showtime`.

## Entwicklung

```bash
fvm flutter analyze
```

```bash
fvm flutter test
```

Tests der Packages laufen im jeweiligen Ordner, z. B.:

```bash
cd packages/recording_repository && fvm flutter test
```

```bash
fvm dart format .
```

Lint-Regeln: [`very_good_analysis`](https://pub.dev/packages/very_good_analysis).

## Architektur

Das Projekt folgt der [Layered Architecture von Very Good Ventures](https://engineering.verygood.ventures/architecture/architecture/) mit vier Schichten. Daten fließen nur von unten nach oben, und jede Schicht greift nur auf die direkt darunterliegende zu.

| Schicht | Ort | Verantwortung |
|---|---|---|
| Presentation | `lib/<feature>/view`, `lib/<feature>/widgets` | Flutter-UI, keine Geschäftslogik |
| Business Logic | `lib/<feature>/bloc` | Blocs/Cubits pro Feature, ohne Flutter-Abhängigkeit |
| Repository | `packages/<domain>_repository` | Kombiniert Data-Clients und wendet Domänenregeln an; ohne Flutter, keine Abhängigkeit zu anderen Repositories |
| Data | `packages/<source>_client` | Rohdaten aus externen Quellen (native APIs, Dateisystem), ohne Domänenlogik |

```
showtime/
├── lib/
│   ├── app/            # Root-Widget
│   │   ├── view/
│   │   └── app.dart    # Barrel-Datei
│   ├── recording/      # Feature: Aufnahme
│   │   ├── bloc/
│   │   ├── view/
│   │   ├── widgets/
│   │   └── recording.dart
│   └── main.dart
├── packages/
│   ├── recording_repository/   # Repository: Quellen, Dateinamen, Aufnahmedauer
│   └── screen_capture_client/  # Data: native Aufnahme (ScreenCaptureKit, Pigeon)
└── test/               # spiegelt die Struktur von lib/
```

Pro Ordner gibt es eine [Barrel-Datei](https://engineering.verygood.ventures/architecture/barrel_files/), die die öffentlichen Dateien exportiert.

## Lizenz

[MIT](LICENSE)
