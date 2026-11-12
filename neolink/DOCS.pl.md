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

## Nagrywanie podglądu
Włącz dla kamery przełącznik **Nagrywaj podgląd** w integracji Neolink. Od tej chwili każdy podgląd
tej kamery jest zapisywany w trakcie oglądania, bez przekodowania, w folderze mediów Home Assistant:
`/media/neolink/<kamera>/<RRRR-MM-DD>/GGMMSS-GGMMSS.mp4` (Media → Moje media → neolink). Gdy nikt
nie ogląda, nic się nie nagrywa, więc nie kosztuje to dodatkowego transferu ani baterii. Stare pliki
zostają, dopóki nie włączysz `record_cleanup` (wtedy raz dziennie znikają starsze niż
`record_keep_days`).

## Nagrania z karty SD
Nagrania, które kamera zapisuje na karcie SD (po wykryciu ruchu), można skopiować do tego samego
folderu co nagrane podglądy, `/media/neolink/<kamera>/<RRRR-MM-DD>/GGMMSS-GGMMSS.mp4`, z nazwą od
początku i końca zdarzenia według kamery, więc pojawiają się na tej samej osi czasu. Integracja
Neolink ma przycisk **Synchronizuj nagrania** (ostatnie 7 dni: porównuje kartę z folderem i kopiuje
to, czego brakuje) oraz akcję `neolink.sync_recordings` (`hours`, `latest: true` tylko dla
najnowszego, np. kilka minut po powiadomieniu o ruchu). Przełącznik kamery **Automatycznie kopiuj
nagrania** sam kopiuje najnowsze nagranie 5 minut po każdym powiadomieniu o ruchu (domyślnie
wyłączony); dashboardy i tak pokazują nagrania z karty i pozwalają skopiować je ręcznie.

Każde kopiowanie zużywa dane komórkowe i trzyma kamerę obudzoną: 30 s nagrania głównego strumienia
Go Plus to około 13 MB i 2-3 minuty przez 4G. `sd_stream: sub` kopiuje mały strumień (ułamek danych,
640×360). Pliki powstają jako `….mp4.part` i dostają nazwę dopiero w całości.

## Mówienie przez kamerę
Integracja Neolink pozwala dashboardowi (np. Home Dashboard) mówić przez głośnik kamery: mikrofon
telefonu lub tabletu idzie przez Home Assistant do tej aplikacji, która koduje dźwięk dla kamery.
Mówienie budzi kamerę; przez 4G głos dociera z opóźnieniem sekundy lub dwóch.

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

**Podgląd na żywo nie ma dźwięku** — do wersji 0.1.0 strumień RTSP niósł dźwięk jako surowe PCM,
które odtwarzacz HLS w Home Assistant pomija, a go2rtc musiał je przekodować do WebRTC, zanim kamera
się obudziła. Od 0.2.0 dźwięk idzie jako AAC i Opus. Jeśli dalej go nie ma, sprawdź w aplikacji
Reolink, czy mikrofon kamery jest włączony.

**Synchronizacja kończy się błędem „the download did not finish”** — przez 4G długie nagranie
głównego strumienia może trwać dłużej niż 5 minut przewidzianych na jeden plik. Wybierz
`sd_stream: sub` albo kopiuj tylko najnowsze nagranie po powiadomieniu o ruchu.

**Nagranie podglądu jest długie, a pokazuje tylko chwilę, i bateria szybko się rozładowała** — do
wersji 0.3.1 podgląd, którego kamera po kilku klatkach przestała wysyłać obraz, czekał na następną
klatkę bez końca i trzymał połączenie z kamerą (w dzienniku `Buffer full on vidsrc ...`, potem tylko
`Connection Lost` co 30 minut). Od 0.3.4 taki podgląd kończy się po 20 s bez klatki i kamera wraca do
uśpienia (0.3.2 i 0.3.3 kończyły sam podgląd, ale potrafiły dalej trzymać połączenie z kamerą). Plik usuń ręcznie.

**Kopiowanie nagrania z karty SD trwa minuty** — przez 4G (przekaźnik Reolink) główny strumień
płynie z prędkością ok. 75 KB/s: 37-sekundowe nagranie (16 MB) kopiuje się ok. 3,5 minuty, a
nagrania kopiują się po kolei. Wybierz `sd_stream: sub`, żeby kopie trwały sekundy (mniejszy obraz).
Do wersji 0.3.2 otwarcie listy najpierw przeszukiwało też całą kartę (kolejne 3,5 minuty).

## Fork
Co dodają łatki i jak wygląda protokół WebSocket (po angielsku): [FORK.md](FORK.md).
