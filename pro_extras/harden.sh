#!/bin/sh
# pro_extras: Moonraker auf das Heimnetz beschränken und zmod.link entfernen
# Aufruf: harden.sh [LAN-CIDR]   (Standard 192.168.1.0/24)

LAN="${1:-192.168.1.0/24}"
MOD_DATA="${PE_MOD_DATA:-/opt/config/mod_data}"
CONF="$MOD_DATA/user.moonraker.conf"
BACKUP="$MOD_DATA/user.moonraker.conf.pe_backup"

case "$LAN" in
    *[!0-9./]*|"") echo "pro_extras: ungültiges Netz '$LAN'"; exit 1 ;;
esac

[ -f "$CONF" ] || touch "$CONF"
[ -f "$BACKUP" ] || cp "$CONF" "$BACKUP"

# vorhandene [authorization]-Sektion entfernen, Rest (z. B. update_manager) behalten
awk '
    /^\[/ { skip = ($0 ~ /^\[authorization\]/) }
    skip { next }
    /^[[:space:]]*$/ { blank++; next }
    { while (blank > 0) { print ""; blank-- } print }
' "$CONF" >"$CONF.tmp"

cat >>"$CONF.tmp" <<CFG

[authorization]
# von pro_extras verwaltet – Zugriff nur aus dem Heimnetz
trusted_clients:
  $LAN
  127.0.0.0/8
cors_domains:
  *.local
  *.lan
CFG

mv "$CONF.tmp" "$CONF"
sync
echo "pro_extras: Moonraker nur noch für $LAN freigegeben (Backup: user.moonraker.conf.pe_backup)"

# zmod.link sicher aus
ZLINK="$MOD_DATA/zlink.txt"
if [ -f "$ZLINK" ] && [ "$(head -n 1 "$ZLINK")" != "0" ]; then
    sed -i '1c\0' "$ZLINK"
fi
killall zlink 2>/dev/null
echo "pro_extras: zmod.link deaktiviert"

# Warnung bei Standard-Root-Passwort "root"
for PY in /usr/bin/python3 /usr/bin/python; do
    [ -x "$PY" ] || continue
    if "$PY" - <<'PYEOF' 2>/dev/null
import crypt, sys
for line in open('/etc/shadow'):
    p = line.split(':')
    if p[0] == 'root' and len(p) > 1 and p[1] not in ('', '*', '!'):
        sys.exit(0 if crypt.crypt('root', p[1]) == p[1] else 1)
sys.exit(1)
PYEOF
    then
        echo "pro_extras: WARNUNG – Root-Passwort ist noch 'root'. Per SSH mit 'passwd' ändern!"
    fi
    break
done
exit 0
