#!/bin/bash

#anything with the value 1 will be completed
SET_HOSTNAME=1
ENABLE_SSH=1
ENABLE_WIFI=1
CONFIGURE_LOCALE=1

#default values for the selected options above
HOSTNAME_VALUE=node1
SSH_PASSWORD_VALUE=raspberry
WIFI_SSID_VALUE=My-ssid
WIFI_PASSWORD_VALUE=My-ssid-password

function set-hostname() {
    CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
    echo ${HOSTNAME_VALUE} >/etc/hostname
    sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t${HOSTNAME_VALUE}/g" /etc/hosts
}

function enable-ssh() {
    FIRSTUSER=`getent passwd 1000 | cut -d: -f1`
    FIRSTUSERHOME=`getent passwd 1000 | cut -d: -f6`
    echo "$FIRSTUSER:"'${PASSWORD_VALUE}' | chpasswd -e
    systemctl enable ssh
}

function enable-wifi() {
    cat >/etc/wpa_supplicant/wpa_supplicant.conf <<'WPAEOF'
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
ap_scan=1

update_config=1
network={
	ssid="${WIFI_SSID_VALUE}"
	psk=${WIFI_PASSWORD_VALUE}
}

WPAEOF
    chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
    rfkill unblock wifi
    for filename in /var/lib/systemd/rfkill/*:wlan ; do
        echo 0 > $filename
    done
}

function configure-locale() {
    rm -f /etc/localtime
    echo "America/New_York" >/etc/timezone
    dpkg-reconfigure -f noninteractive tzdata
    cat >/etc/default/keyboard <<'KBEOF'
XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS=""
KBEOF
    dpkg-reconfigure -f noninteractive keyboard-configuration
}

## things start to happen here ##

# exit if non-root user detected
if [ $(id -u) -ne 0 ]; then
	echo "This script must be run as root, try again with sudo"
	exit 1
fi

if [ "$SET_HOSTNAME" = 1 ]; then
    set-hostname
fi 

if [ "$ENABLE_SSH" = 1 ]; then
    enable-ssh
fi

if [ "$ENABLE_WIFI" = 1 ]; then
    enable-wifi
fi

if [ "$CONFIGURE_LOCALE" = 1 ]; then
    configure-locale
fi

echo "Script complete."