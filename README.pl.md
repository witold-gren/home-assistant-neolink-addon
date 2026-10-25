# Neolink dla Home Assistant — aplikacja (dodatek)

🇬🇧 [English version](README.md)

Aplikacja (dawniej dodatek) Home Assistant dla **kamer Reolink bez lokalnego API** — kamer bateryjnych
bez Home Hub oraz kamer 4G LTE, takich jak Reolink Go Plus / Go G330. Uruchamia fork
[Neolink](https://github.com/QuantumEntangledAndy/neolink) z API WebSocket; encje tworzy
[integracja Neolink](https://github.com/witold-gren/home-assistant-neolink-integration). Bez MQTT.

Co dostajesz razem z integracją:
- obraz na żywo przez RTSP (go2rtc / encja kamery), który nie utrzymuje kamery bateryjnej w stanie
  wybudzenia,
- zdjęcia z pamięci, które nie budzą kamery, oraz zdjęcie z ostatniego zdarzenia ruchu,
- ruch i typ wykrycia (osoba, pojazd, zwierzę) z powiadomień push Reolink, nawet gdy kamera śpi,
- baterię, ładowanie, sygnał 4G, kartę SD i ustawienia kamery (PIR, dioda, podczerwień, nagrywanie,
  syrena …).

## Instalacja
1. **Ustawienia → Aplikacje → Sklep z aplikacjami → ⋮ → Repozytoria**, dodaj
   `https://github.com/witold-gren/home-assistant-neolink-addon`.
2. Zainstaluj **Neolink (Reolink battery & 4G cameras)** — Neolink jest kompilowany podczas instalacji
   (kilka minut na PC, znacznie dłużej na Raspberry Pi).
3. Dodaj kamery w konfiguracji aplikacji (nazwa, UID, hasło urządzenia, discovery) i uruchom ją.
4. Zainstaluj [integrację Neolink](https://github.com/witold-gren/home-assistant-neolink-integration)
   (niestandardowe repozytorium HACS) — zostanie wykryta automatycznie.

Dokumentacja: [neolink/DOCS.pl.md](neolink/DOCS.pl.md); fork i jego protokół WebSocket (po angielsku):
[neolink/FORK.md](neolink/FORK.md).

## Struktura repozytorium
| Ścieżka | Co to jest |
|---|---|
| `neolink/` | aplikacja: `config.yaml`, `Dockerfile` (buduje fork), `run.sh`, tłumaczenia, dokumentacja |
| `neolink/patches/` | łatki na oryginalny Neolink (API WebSocket, powiadomienia push, poprawki RTSP) |
| `deploy.sh` | do developmentu: kopiuje aplikację na zamontowany udział `addons` |

## Licencja
Neolink jest na licencji AGPL-3.0-or-later (© autorzy Neolink); łatki i ta aplikacja są na tej samej
licencji — zobacz [LICENSE](LICENSE).
