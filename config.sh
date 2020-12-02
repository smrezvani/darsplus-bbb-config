#!/bin/bash

# Pull in the helper functions for configuring BigBlueButton
source /etc/bigbluebutton/bbb-conf/apply-lib.sh

# Latest version of properties
cat << EOF
╔══════════════════════════════════════════════════════════════════════════=╗
║                                                                           ║
║ Copy the latest version of "bigbluebutton.properties" file to respective  ║
║ destination with correct permission                                       ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF

cp /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties bigbluebutton.properties.org
cp bigbluebutton.properties /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
chmod 444 /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
sleep 5

FQDN=$(sed -n -e '/screenshareRtmpServer/ s/.*\= *//p' bigbluebutton.properties.org)
SALT=$(sed -n -e '/securitySalt/ s/.*\= *//p' bigbluebutton.properties.org)

sed -i "s,^bigbluebutton.web.serverURL=.*,bigbluebutton.web.serverURL=https://$FQDN,g" /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
sed -i "s,^screenshareRtmpServer=.*,screenshareRtmpServer=$FQDN,g" /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
sed -i "s,^securitySalt=.*,securitySalt=$SALT,g" /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

# Last version of settings
HTML5_CONFIG=/usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

yq w -i $HTML5_CONFIG public.app.audioChatNotification true
yq w -i $HTML5_CONFIG public.app.clientTitle DarsPlus Live Session
yq w -i $HTML5_CONFIG public.app.appName DarsPlus client
yq w -i $HTML5_CONFIG public.app.copyright "@2020 DarsPlus ltd."
yq w -i $HTML5_CONFIG public.app.helpLink https://darsplus.com/liveclass/
yq w -i $HTML5_CONFIG public.app.enableNetworkInformation true
#yq w -i $HTML5_CONFIG public.app.enableLimitOfViewersInWebcam true
#yq w -i $HTML5_CONFIG public.app.mirrorOwnWebcam true
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

cat << EOF
╔═════════════════════════════════════════════════════=╗
║                                                      ║
║       Change HTML5 client & default web page         ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF

sed -i "s:Source Sans Pro:Vazir:g" /usr/share/meteor/bundle/programs/web.browser/head.html
sed -i '2i<link href="https://cdn.jsdelivr.net/gh/rastikerdar/vazir-font@v26.0.2/dist/font-face.css" rel="stylesheet" type="text/css" />' /usr/share/meteor/bundle/programs/web.browser/head.html

cd /var/www/bigbluebutton-default && rm -rf * && wget https://github.com/smrezvani/bbb-default-page/archive/main.zip && unzip main.zip && rm -rf main.zip && mv bbb-default-page-main/* . && rm -rf bbb-default-page-main
sleep 2

cat << EOF
╔════════════════════════════════════════════=╗
║                                             ║
║       All setting done successfully         ║
║                                             ║
╚═════════════════════════════════════════════╝
EOF

enableUFWRules
