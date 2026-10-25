# Datenschutz-Check Z-Mod (Stand 2026-10-25)

Geprüft: dieses Repo (`ghzserg/zmod` – nur Doku + USB-Hilfsskripte) und der
eigentliche Mod-Code `ghzserg/zmod_ff5m` (Branch 1.6), der per Moonraker-Updater
auf den Drucker kommt.

## Kurzfazit

Z-Mod schickt **von sich aus keine Telemetrie** irgendwohin. Es gibt keinen
versteckten "Phone-Home". Alle Verbindungen nach außen sind entweder
Update-Abfragen bei GitHub oder Funktionen, die du **selbst aktivieren musst**.
Die größten Risiken sind (1) die optionale Cloud *zmod.link* (Server in
Moskau) und (2) die sehr offene lokale Konfiguration.

## Was nach außen geht

| Was | Ziel | Standard | Bewertung |
|---|---|---|---|
| Update-Check Mod/Klipper/Moonraker/Fluidd/Plugins | github.com (`ghzserg/*`) | an (nur Prüfen, Installation per Klick) | GitHub sieht deine IP. Du vertraust dem Autor als Lieferant aller Updates (Klipper, Moonraker, Fluidd sind seine Forks). |
| `CHECK_MD5` / Reparatur Stock-Dateien | api.github.com (`ghzserg/FF`) | nur bei Aufruf | unkritisch |
| **ZLINK / zmod.link Cloud** | `zmod.link:2222` → 185.56.162.236, **Selectel, Moskau, RU** | **aus** (`mod_data/zlink.txt` = `0`) | Reverse-SSH-Tunnel, der **Moonraker (volle Druckersteuerung) und die Kamera** zum Server des Autors durchreicht. Wer den Server betreibt bzw. kontrolliert, kann deinen Drucker bedienen und die Kamera sehen. **Nicht aktivieren.** |
| `ZSSH_ON` (Telegram-Bot-Tunnel) | ein SSH-Server, den **du** angibst | aus | OK, wenn es dein eigener Server ist. |
| Telegram-Bot / notify-Plugin | Telegram bzw. die Dienste, die du konfigurierst | aus | nur das, was du einrichtest |
| `ENABLE_EXTRA_PLUGINS` | fremde Plugin-Repos | aus | Fremdcode – nur bewusst aktivieren |
| FlashForge-Cloud (Stock) | *.flashforge.com, sz3dp.com, polar3d.com, qiniuapi.com | **an** (`CHINA_CLOUD=1`) | Die Original-Firmware sendet Fotos/Videos/Telemetrie nach China. Z-Mod kann das per `/etc/hosts` blocken. |

Geprüft wurde dazu u. a.: `.shell/zlink` (Binary, Strings analysiert: startet
nur `dbclient … -R …:127.0.0.1:7125 -R …:127.0.0.1:8080 <user>@zmod.link`),
`zlink.sh`, `S98zssh`, `zssh.sh`, `zupdate.sh`, `zversion.sh`, `zcheckmd5.sh`,
`moonraker.conf`, `fix_config.sh`, `hosts`.

## Lokale Sicherheit (Heimnetz)

- Moonraker lauscht auf `0.0.0.0:7125`, **ohne API-Key**, und Z-Mod legt
  `trusted_clients: 0.0.0.0/0` an → jedes Gerät im Netz hat volle Kontrolle
  (Drucken, Heizen, G-Code, vordefinierte Shell-Befehle).
- SSH (dropbear, Port 22) mit Root-Login; `RESET_PASSWD` setzt das
  Root-Passwort auf `root`.
- Im Log-Archiv (`config_*.tar.gz` für Bug-Reports) sind `ssh.key` und
  `notify.txt` ausgeschlossen, aber WLAN-/Netzwerk-Konfiguration und Logs
  können drin sein – vor dem Hochladen in ein GitHub-Issue reinschauen.

## Empfehlungen

1. Chinesische Cloud blocken (Fluidd-Konsole):
   `SAVE_ZMOD_DATA CHINA_CLOUD=0` → Neustart.
   (Stock-Firmware-Updates gehen dann nur nach temporärem Wieder-Einschalten.)
2. zmod.link **nicht** nutzen; zur Sicherheit `ZLINK_OFF` ausführen.
   Für Fernzugriff lieber eigenes VPN (WireGuard/Tailscale) oder die eigene
   Home-Assistant-/Reverse-Proxy-Infrastruktur.
3. Drucker **nicht** per Portweiterleitung ins Internet stellen. Ideal:
   eigenes IoT-VLAN / Gast-WLAN, ausgehend nur github.com erlauben.
4. Moonraker einschränken – in `mod_data/user.moonraker.conf`
   `trusted_clients` auf dein Heimnetz setzen, z. B.:

   ```ini
   [authorization]
   trusted_clients:
     192.168.1.0/24
     127.0.0.0/8
   cors_domains:
     http://*.local
   ```
   (Den Eintrag `*.zmod.link:*` entfernen, wenn du die Cloud nicht nutzt.)
5. Root-Passwort per SSH mit `passwd` auf etwas Eigenes ändern.
6. Updates nicht blind einspielen: der Autor kontrolliert Klipper-, Moonraker-
   und Fluidd-Forks. Bisher ist nichts Auffälliges im Code, aber das ist eine
   Vertrauensfrage bei jedem Update.
