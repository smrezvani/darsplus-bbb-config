#!/bin/bash

# Pull in the helper functions for configuring BigBlueButton
source /etc/bigbluebutton/bbb-conf/apply-lib.sh
SCRIPT_ROOT=/root/darsplus-bbb-config
# Functions
function backup_properties() {
    cp /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties $SCRIPT_ROOT/bigbluebutton.properties.org
    echo "  - Backup bigbluebutton.properties ------------------------ [Ok]"
}

# Latest version of properties
cat << EOF
╔══════════════════════════════════════════════╗
║                                              ║
║           Start to apply configs...!         ║
║       This script made for DarsPlus.com      ║
║ *** Attention: Don't run on your servers *** ║
╚══════════════════════════════════════════════╝

EOF
printf "This script will run in 5 sec. Press Ctrl+C if you want to stop running the script!!!\n\n"

sleep 5

if [[ ! -f $SCRIPT_ROOT/bigbluebutton.properties.org ]]
then
    backup_properties
else
    printf "bigbluebutton.properties backup exist. Do you want overwrite it?\n"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) backup_properties; break;;
            No ) break;;
        esac
    done
fi


cp $SCRIPT_ROOT/bigbluebutton.properties /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
chmod 444 /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
sleep 1

# FQDN=$(sed -n -e '/screenshareRtmpServer/ s/.*\= *//p' bigbluebutton.properties.org)
FQDN=$HOSTNAME
SECRET=$(bbb-conf --secret > $SCRIPT_ROOT/bbb-secret && sed -n -e '/Secret/ s/.*\= *//p' bbb-secret)

sed -i "s,^bigbluebutton.web.serverURL=.*,bigbluebutton.web.serverURL=https://$FQDN,g" /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

sleep 1

sed -i "s,^screenshareRtmpServer=.*,screenshareRtmpServer=$FQDN,g" /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

sleep 1

sed -i "s,^securitySalt=.*,securitySalt=$SECRET,g" /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "  - Apply change to bigbluebutton.properties --------------- [Ok]"
sleep 1

# Last version of settings
HTML5_CONFIG=/usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

yq w -i $HTML5_CONFIG public.app.audioChatNotification true
yq w -i $HTML5_CONFIG public.app.clientTitle DarsPlus Live Session
yq w -i $HTML5_CONFIG public.app.appName DarsPlus client
yq w -i $HTML5_CONFIG public.app.copyright "@2020 DarsPlus ltd."
yq w -i $HTML5_CONFIG public.app.helpLink https://darsplus.com/liveclass/
yq w -i $HTML5_CONFIG public.app.enableNetworkInformation true
#yq w -i $HTML5_CONFIG public.app.enableLimitOfViewersInWebcam true
yq w -i $HTML5_CONFIG public.app.mirrorOwnWebcam false
yq w -i $HTML5_CONFIG public.app.breakoutRoomLimit 2
yq w -i $HTML5_CONFIG public.app.defaultSettings.application.overrideLocale fa
yq w -i $HTML5_CONFIG public.kurento.wsUrl wss://$FQDN/bbb-webrtc-sfu
yq w -i $HTML5_CONFIG public.captions.fontFamily Vazir
yq w -i $HTML5_CONFIG public.note.enabled true
yq w -i $HTML5_CONFIG public.note.url https://$FQDN/pad
yq w -i $HTML5_CONFIG public.note.config.showLineNumbers true
yq w -i $HTML5_CONFIG public.note.config.rtl true
yq w -i $HTML5_CONFIG public.clientLog.external.enabled true

sleep 1
chmod 444 /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml
chown 995:995 /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

echo "  - Apply new seeting to BBB setting.yml ------------------- [Ok]"

sleep 1

sed -i "s:Source Sans Pro:Vazir:g" /usr/share/meteor/bundle/programs/web.browser/head.html
sed -i '2i<link href="https://cdn.jsdelivr.net/gh/rastikerdar/vazir-font@v26.0.2/dist/font-face.css" rel="stylesheet" type="text/css" />' /usr/share/meteor/bundle/programs/web.browser/head.html

rm -rf /var/www/bigbluebutton-default/* && cp -r bbb-default-page-main/* /var/www/bigbluebutton-default/

printf "  - Install default page for BBB --------------------------- [Ok]\n\n"

sleep 1

echo "Apply UFW rules..."

enableUFWRules

cat << EOF

╔═════════════════════════════════════════════╗
║                                             ║
║       All setting done successfully         ║
║                                             ║
╚═════════════════════════════════════════════╝
EOF
