# recording_repository

Repository-Schicht von Showtime: verwaltet Aufnahmen und die aufnehmbaren Quellen.

- Bietet Bildschirme und sichtbare Fenster als Quellen an. Ausgeblendet werden zu kleine, namenlose und Showtime-eigene Fenster.
- Speichert Aufnahmen als `Showtime <Datum> at <Uhrzeit>.mp4` im Standardordner (`~/Movies/Showtime` auf macOS).
- Misst die Dauer jeder Aufnahme und übersetzt Plattformfehler in `RecordingFailure`.

Nutzt intern [`screen_capture_client`](../screen_capture_client).
