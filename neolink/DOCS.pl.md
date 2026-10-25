# Neolink (Reolink battery & 4G cameras)

🇬🇧 [English version](DOCS.md)

Most dla kamer Reolink, których nie obsługuje integracja Reolink w Home Assistant: kamer bateryjnych
bez Home Hub oraz kamer 4G LTE (seria Go). Aplikacja uruchamia fork
[Neolink](https://github.com/QuantumEntangledAndy/neolink) z API WebSocket (tryb `ws-rtsp`).
Encje tworzy integracja **Neolink** z
[home-assistant-neolink-integration](https://github.com/witold-gren/home-assistant-neolink-integration) —
MQTT nie jest potrzebne.

- Po uruchomieniu aplikacja zgłasza się do Supervisora: Home Assistant pokazuje wykrytą integrację
  Neolink.
- **RTSP**: `rtsp://ha:<password>@<HA address>:8564/<name>/sub`; hasło jest w
  `/data/rtsp_password` (integracja dostaje je w zgłoszeniu).
- **API WebSocket**: port 3002, dostępny tylko w sieci HA (można go wystawić w panelu Sieć);
  token jest w `/data/ws_token`.
- Fork jest kompilowany ze źródeł podczas instalacji aplikacji (kilka minut na PC, znacznie dłużej na
  Raspberry Pi).

Przetestowane z Reolink Go Plus / Go G330 (firmware v3.0.0.662) przez 4G.

## Konfiguracja
```yaml
cameras:
  - name: Garden          # litery, cyfry, _ (część ścieżki RTSP)
    uid: 95270000ABCDEFGH  # 16 znaków, zaczyna się od 9527 (aplikacja Reolink → informacje o urządzeniu)
    username: admin
    password: "…"         # hasło URZĄDZENIA ustawione w aplikacji Reolink
    discovery: cellular   # cellular dla kamer 4G; relay / map / remote / local
    stream: subStream     # subStream oszczędza transfer; mainStream / both
    idle_disconnect: true
```

## Kamera 4G: transfer i bateria
- `discovery: cellular` — łączy się wyłącznie przez serwery Reolink.
- `stream: subStream` — około 110 kbit/s (0,8 MB na minutę oglądania).
- `idle_disconnect: true` — rozłącza 30 s po ostatnim użyciu; zdjęcie lub polecenie budzi kamerę
  (pierwszy obraz po około 15 s).
- `battery_minutes` — odczytuje baterię tylko podczas połączenia, nigdy nie budzi kamery.
- `push: true` — ruch z powiadomień push Reolink (Firebase). Kamera zgłasza wykrycia PIR nawet
  podczas snu; czujnik ruchu w HA pozostaje włączony przez `motion_seconds` (domyślnie 30 s).
  Wyłączenie PIR w kamerze (przełącznik „Czujnik PIR”) wycisza też powiadomienia.
- `motion: false` — dodatkowe nasłuchiwanie ruchu, gdy kamera jest połączona; włączaj świadomie.

## Hasło
`password` to hasło **urządzenia** ustawione w aplikacji Reolink, często inne niż hasło do konta.
Kilka nieudanych logowań może na jakiś czas zablokować kamerę.

## Rozwiązywanie problemów
`log_level: debug` zapisuje w dzienniku szczegóły z samego Neolinka, w tym treść każdego
powiadomienia push Reolink (linia `push payload: ...` zaraz po `push notification (motion)`).
Biblioteki sieciowe i protokół kamery pozostają na poziomie `info`. Potem wróć do `info`.

## Fork
Co dodają łatki i jak wygląda protokół WebSocket (po angielsku): [FORK.md](FORK.md).
