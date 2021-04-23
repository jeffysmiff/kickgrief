#!/bin/bash

# This script needs to be run with root privs so check user
if [ "${USER}" != "root" ]
then
	echo "This script needs to be run with sudo e.g."
	echo "sudo ./${0}"
	exit 1
fi

# First update the system to make sure all the latest stuff is on here
apt update
apt upgrade -y

# Set the hostname
hostnamectl set-hostname xboxgateway

# Set eth0 IP address
cat <<EOF > /etc/network/interfaces.d/eth0
allow-hotplug eth0
iface eth0 inet static
    address 192.168.101.1
    netmask 255.255.255.0
    network 192.168.101.0
    broadcast 192.168.101.255
EOF
service networking restart
ifup eth0 

# Set up hosts file
cat <<EOF >/etc/hosts
127.0.0.1	localhost
::1		localhost ip6-localhost ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters

127.0.1.1		xboxgateway
EOF

# Install the packages we need
apt install -y dnsmasq apache2 libapache2-mod-wsgi-py3 python3.7 python3-pip

# Install flask
pip3 install flask

# Set up iptables
iptables -F 
iptables -t nat -F
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE  
iptables -A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT  
iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT

# Persist the rules
sh -c 'iptables-save > /etc/iptables.rules'
cat <<EOF > /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

# Print the IP address
_IP=$(hostname -I) || true
if [ "$_IP" ]; then
  printf "My IP address is %s\n" "$_IP"
fi

iptables-restore < /etc/iptables.rules
exit 0
EOF

# enable IP forwarding
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p > /dev/null

# Set up DNSMASQ
cat <<EOF > /etc/dnsmasq.conf
interface=eth0      # Use interface eth0  
listen-address=192.168.101.1 # Explicitly specify the address to listen on  
bind-interfaces      # Bind to the interface to make sure we aren't sending things elsewhere  
server=8.8.8.8       # Forward DNS requests to Google DNS  
domain-needed        # Don't forward short names  
bogus-priv           # Never forward addresses in the non-routed address spaces.  
dhcp-range=192.168.101.50,192.168.101.150,12h # Assign IP addresses between 172.24.1.50 and 172.24.1.150 with a 12 hour lease time
EOF

# Restart DNSMASQ
systemctl restart dnsmasq

# Install website
CURRENT_DIR=`pwd`
cp -R kickgrief /var/www/
cd /var/www/
tar xvf kickgrief.tar

# Assign wlan0 IP to variable
MY_IP=$(/sbin/ip -o -4 addr list wlan0 | awk '{print $4}' | cut -d/ -f1)

cat <<EOF > /etc/apache2/sites-available/kickgrief.conf
<VirtualHost *:80>
                ServerName ${MY_IP}
                WSGIScriptAlias / /var/www/kickgrief/kickgrief.wsgi
                <Directory /var/www/kickgrief/kickgrief/>
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
a2ensite kickgrief

# Reload Apache2 config
systemctl reload apache2
