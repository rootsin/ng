#!/bin/bash
echo "...."
echo "...."
echo ""Uninstalling nrpe and nagios plugin from the server...:
/etc/init.d/xinetd stop
yum -y remove xinetd
rm -rf /etc/xinetd.d
rm -rf /usr/local/nagios
sed -i '/'nagios'/d' /etc/sudoers
sed -i '/'nrpe'/d' /etc/services
userdel nagios

echo "...."
echo "...."
echo "...."
echo "...."
echo "Attention !!!!"           
echo "...."
echo "...."
echo "...."
echo "...."

echo "Close down the port 5666 in Firewall.."
