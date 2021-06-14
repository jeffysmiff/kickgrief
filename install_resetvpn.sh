#!/bin/bash

# This script needs to be run with root privs so check user
if [ "${USER}" != "root" ]
then
	echo "This script needs to be run with sudo e.g."
	echo "sudo ./${0} <INTERNET NIC>"
	exit 1
fi

if [ -z "${1}" ]
then
  echo "Must specify Internet-facing NIC"
  echo "sudo ./${0} <INTERNET NIC>"
  exit 1
fi

INTERNET_NIC=${1}

# First update the system to make sure all the latest stuff is on here
apt update
apt upgrade -y

# Set the hostname
hostnamectl set-hostname vpngateway

# Install the packages we need
apt install -y dnsmasq apache2 libapache2-mod-wsgi-py3 python3.5 python3-pip

# Install flask
pip3 install flask

# Install website
CURRENT_DIR=`pwd`
cp -R resetvpn /var/www/

# Assign ${INTERNET_NIC} IP to variable
MY_IP=$(/sbin/ip -o -4 addr list ${INTERNET_NIC} | awk '{print $4}' | cut -d/ -f1)

cat <<EOF > /etc/apache2/sites-available/resetvpn.conf
<VirtualHost *:80>
                ServerName ${MY_IP}
                WSGIScriptAlias / /var/www/resetvpn/resetvpn.wsgi
                <Directory /var/www/resetvpn/resetvpn/>
                        Options FollowSymLinks
                        AllowOverride None
                        Require all granted
                </Directory>
                ErrorLog ${APACHE_LOG_DIR}/error.log
                LogLevel warn
                CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Allow the Apache user free run of the system
cat <<EOF > /etc/sudoers.d/011_www-data-nopasswd
www-data ALL=(ALL) NOPASSWD: ALL
EOF

# Enable site
a2ensite resetvpn

# Reload Apache2 config
systemctl reload apache2