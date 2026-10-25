#!/bin/sh
# Wird von ENABLE_PLUGIN name=pro_extras aufgerufen (danach folgt FIRMWARE_RESTART).
# Die eigentliche Einrichtung erledigt _PE_AUTOSETUP in pro_extras.cfg nach dem Neustart.
chmod +x /opt/config/mod_data/plugins/pro_extras/*.sh 2>/dev/null
echo "Plugin pro_extras installiert – Einrichtung startet ca. 30 s nach dem Klipper-Neustart."
