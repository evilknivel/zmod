# zmod-pro-extras

Z-Mod-Plugin für den **FlashForge Adventurer 5M Pro**. Einmal installiert, richtet es den Drucker
mit sinnvollen Defaults ein, sperrt die Clouds und rüstet ein paar Funktionen nach.

> Nur für AD5M / AD5M Pro gedacht. **Nicht** auf AD5X oder Creator 5 Pro installieren
> (dort hat `eboard:PA1` eine andere Funktion).

## Was das Plugin macht

**Einmalig nach der Installation (automatisch):**

| Was | Wie |
|---|---|
| China-Cloud von FlashForge blockiert | `SAVE_ZMOD_DATA CHINA_CLOUD=0` |
| zmod.link-Tunnel (Server in Moskau) aus | `ZLINK_OFF` + `zlink.txt` auf 0 |
| Moonraker nur noch aus dem Heimnetz erreichbar | `trusted_clients: 192.168.1.0/24`, `*.zmod.link`-CORS entfernt |
| Empfohlene Druckstart-Defaults | `CLOSE_DIALOGS=2 PRINT_LEVELING=1 USE_KAMP=1 CLEAR=LINE_PURGE` |
| Offizielles `recommend`-Plugin des Z-Mod-Autors | `ENABLE_PLUGIN name=recommend` (E0011/E0017-Fix, MD5-Prüfung, SCV-Fix, Kollisionserkennung …) |
| Warnung bei Root-Passwort `root` | Hinweis in der Konsole |
| Danach | automatischer Reboot |

**Beim nächsten Start:** Dialog **„Klipper 13 aktivieren?“** (Fluidd-Popup, falls Fluidd offen ist –
sonst jederzeit per `PRO_EXTRAS_KLIPPER13`). Das Flashen der MCU-Firmware wird bewusst nicht
ohne Klick ausgelöst.

**Dauerhaft:**

- **Temperatursensor `head`** auf dem Extruder-Board in Fluidd/Mainsail – auch mit Stock-Klipper 11.
- **Druckkopf-Überwachung:** Warnung ab 60 °C, Pause ab 75 °C (einstellbar).
- **Automatische Luftfilterung:** beim Druckstart wird nach Betttemperatur gewählt
  - Bett ≥ 90 °C (ABS/ASA/PC) → interne Umluft durch den Filter
  - darunter (PLA/PETG) → Abluft nach außen
  - nach dem Druck 10 min Nachlauf, dann aus
- **Optional:** Filter im Leerlauf, wenn der TVOC-Wert eine Schwelle überschreitet
  (nur mit Stock-Klipper 11 – unter Klipper 13 stellt Z-Mod den TVOC-Sensor nicht bereit).

## Installation

1. In Fluidd: **Configuration → mod_data → `user.moonraker.conf`** öffnen und ans Ende anfügen:

   ```ini
   [update_manager pro_extras]
   type: git_repo
   channel: dev
   path: /root/printer_data/config/mod_data/plugins/pro_extras
   origin: https://github.com/evilknivel/zmod-pro-extras.git
   is_system_service: False
   primary_branch: main
   ```

2. Speichern.
3. In der Konsole: `ENABLE_PLUGIN name=pro_extras`
4. Warten – der Drucker richtet sich ein und startet 1–2× neu. Fertig.

**In Orca nachziehen** (kann das Plugin nicht übernehmen): Upload als „Octo/Klipper“
(`IP:7125`), „Exclude/Label objects“ an, „Arc Move Approximation“ aus und das
[MD5-Preprocess-Script](https://github.com/ghzserg/zmod_preprocess/releases/latest) als
Post-Processing eintragen – `recommend` schaltet die MD5-Prüfung ein, beschädigte Dateien
werden dann vor dem Druck erkannt und gelöscht.

Updates kommen danach über **Fluidd → Settings → Software Updates** (`pro_extras`).

> Anderes Heimnetz? Vor Schritt 3 in der Konsole: `SAVE_VARIABLE VARIABLE=pe_lan VALUE='"192.168.178.0/24"'`

## Befehle

| Befehl | Zweck |
|---|---|
| `PRO_EXTRAS_STATUS` | Einstellungen + aktuelle Sensorwerte |
| `PRO_EXTRAS_SET …` | Einstellungen ändern (siehe unten) |
| `PRO_EXTRAS_SETUP` | Grundeinrichtung erneut ausführen |
| `PRO_EXTRAS_KLIPPER13` | Dialog für den Umstieg auf Klipper 13 |

`PRO_EXTRAS_SET` – alle Parameter optional, Werte bleiben über Neustarts erhalten:

| Parameter | Standard | Bedeutung |
|---|---|---|
| `HEAD_WARN` | 60 | Warnung ab °C am Druckkopf (0 = aus) |
| `HEAD_PAUSE` | 75 | Pause ab °C am Druckkopf (0 = aus) |
| `AIR` | 1 | Automatische Luftfilterung an/aus |
| `AIR_HOT_BED` | 90 | Ab dieser Betttemperatur gilt das Material als „heiß“ |
| `AIR_HOT_MODE` | INTERNAL | Modus für heiße Materialien: `INTERNAL`, `EXTERNAL`, `OFF` |
| `AIR_COLD_MODE` | EXTERNAL | Modus für PLA/PETG: `INTERNAL`, `EXTERNAL`, `OFF` |
| `AIR_RUNON` | 10 | Nachlauf nach dem Druck in Minuten (0 = sofort aus) |
| `TVOC_LIMIT` | 0 | TVOC-Schwelle für Filter im Leerlauf (0 = aus) |
| `K13_ASK` | 1 | Beim Start nach Klipper 13 fragen |
| `LAN` | 192.168.1.0/24 | Netz, das auf Moonraker zugreifen darf (wirksam nach `REBOOT`) |

Beispiel: `PRO_EXTRAS_SET HEAD_WARN=55 AIR_RUNON=15`

**Tipp:** Die Druckkopf-Grenzwerte sind Schätzwerte. Schau dir bei den ersten Drucken an, welche
Werte `head` normal erreicht, und stell die Grenzen etwas darüber ein. Am Touchscreen des
Druckers die eigene Filtersteuerung ausschalten, damit sich beide nicht in die Quere kommen.

## Klipper 13 – bitte lesen

- Umstieg: Dialog bestätigen → Melodie abwarten → **ausschalten, 10 s warten, einschalten**.
- **Vor einem Stock-Firmware-Update oder dem Entfernen von Z-Mod** immer erst `UPDATE_MCU`
  ausführen (zurück auf Klipper 11) und dieses Plugin deaktivieren.
- Zurück zu Stock-Klipper: `UPDATE_MCU FORCE=11`.
- Unter Klipper 13 entfällt der TVOC-Sensor (Z-Mod definiert ihn dort nicht).

## Home Assistant & Spoolman (optional)

Moonraker ist nach der Einrichtung aus `192.168.1.0/24` ohne API-Key erreichbar. Damit gibt es zwei Wege:

1. **Einfach:** HACS-Integration **„Moonraker“** in Home Assistant installieren, IP des Druckers
   angeben – fertig. Temperaturen (inkl. `head`), Fortschritt, Kamera, Steuerung.
2. **MQTT:** Vorlage `moonraker/mqtt_homeassistant.conf.example`.

Weitere Vorlagen im Ordner `moonraker/`:

- `homeassistant_automation.yaml.example` – Steckdose nach dem Druck ausschalten, sobald die Düse kalt ist
- `spoolman.conf.example` – Filamentverwaltung mit externem Spoolman-Server

Alternativ ohne HA: Z-Mod kann den Pro selbst ausschalten – `SAVE_ZMOD_DATA PRO_POWEROFF_TIMEOUT=10`.

## Deinstallation

`DISABLE_PLUGIN name=pro_extras`

Die Einstellungen (Cloud-Sperre, Moonraker-Freigabe, `recommend`) bleiben bewusst erhalten.
Die ursprüngliche Moonraker-Konfiguration liegt unter `mod_data/user.moonraker.conf.pe_backup`.

## Hinweise

- Ungetestet auf echter Hardware – Feedback willkommen.
- Baut ausschließlich auf offiziellen Z-Mod-Schnittstellen auf (Plugin-System, `SAVE_ZMOD_DATA`,
  `AIR_CIRCULATION_*`, `UPDATE_MCU`), Z-Mod-Dateien werden nicht verändert.
