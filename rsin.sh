#!/bin/bash


tmp=tmp
nrpe="/usr/local/nagios/libexec/check_disk -w 20% -c 10%"
nrpe1=/usr/local/nagios/etc/nrpe.cfg
rsin=/usr/local/src/rsin


#get IP of Nagios server  

echo -n "Enter your Nagios server IP: "
read ip

echo "Installing nagios/nrpe..Hang on there..."


#Install necessary libraries and modules

yum -y install  gcc glibc glibc-common gd gd-devel make net-snmp openssl-devel xinetd

#Add nagios user

useradd nagios


#Install Nagios plugin

mkdir $rsin

cd $rsin

wget http://nagios-plugins.org/download/nagios-plugins-2.0.3.tar.gz
tar -xvf nagios-plugins-2.0.3.tar.gz
cd nagios-plugins-2.0.3

#Install and configure nagios plugin

./configure
make
make install
chown nagios.nagios /usr/local/nagios
chown -R nagios.nagios /usr/local/nagios/libexec

#Install nrpe

cd $rsin

wget http://garr.dl.sourceforge.net/project/nagios/nrpe-2.x/nrpe-2.15/nrpe-2.15.tar.gz
tar xzf nrpe-2.15.tar.gz
cd nrpe-2.15

#Install and configure Nrpe

./configure
make all
make install-plugin
make install-daemon
make install-daemon-config
make install-xinetd



#Lets add IP of your nagios server

sed -i 's/127.0.0.1/127.0.0.1 '$ip'/g'  /etc/xinetd.d/nrpe

#sed -i '/^only_from/ s/$/ '$ip'/' /etc/xinetd.d/nrpe

#Add port to services

echo "nrpe            5666/tcp                 #NRPE" >> /etc/services


cd $rsin

#Add commands

wget http://linuxshooter.com/src/nrp -O $rsin/nrp

cat $rsin/nrp >> $nrpe1


#Add Custom commands

cd /usr/local/nagios/libexec/
wget http://linuxshooter.com/src/check_logfiles
wget http://linuxshooter.com/src/check_eximmailqueue
wget http://linuxshooter.com/src/check_dovecot
chown nagios: check_logfiles  check_eximmailqueue check_dovecot
chmod 755 check_logfiles check_eximmailqueue check_dovecot
cd /usr/local/nagios/etc/
wget http://linuxshooter.com/src/exim_log.cfg
usermod -G mail nagios


#Add user to sudoers

echo "Defaults:nagios !requiretty" >> /etc/sudoers
echo "nagios ALL=NOPASSWD:/usr/sbin/exim -bpc" >> /etc/sudoers


#get back into working directory

cd $rsin

# Create tmp directory for our work

if [ -d "$tmp" ]; then
echo ""
else
mkdir ./tmp
echo ""
fi


#Check partition and mounted folder for server disk

df -h | awk '{print $1}' > ./tmp/pt
df -h | awk '{print $6}' > ./tmp/mnt

#Remove Filesystem and Mounted from our tmp file

sed -i '/'Filesystem'/d' ./tmp/pt
sed -i '/'Mounted'/d' ./tmp/mnt

#check if the disk command is alrady added or not

sed -i '/'check_disk'/d' $nrpe1

#Add partition & Mount to array 

IFS=$'\n' read -d '' -r -a pt < ./tmp/pt
IFS=$'\n' read -d '' -r -a mnt < ./tmp/mnt

#For $ if loop for disk parttion to be added in nrpe.cfg
#If there is any custom partition name then you will need to add that partition manually in nrpe.cfg to get it monitor.

for ((i=0;i<${#mnt[@]}; i++)) do

if [ ${mnt[$i]} = "/" ]; then
echo "command[check_disk]=$nrpe "${pt[$i]}"" >> $nrpe1

elif [ ${mnt[$i]} = "/home" ]; then
echo "command[check_disk_home]=$nrpe "${pt[$i]}"" >> $nrpe1

elif [ ${mnt[$i]} = "/var" ]; then
echo "command[check_disk_var]=$nrpe "${pt[$i]}"" >> $nrpe1

elif [ ${mnt[$i]} = "/tmp" ]; then
echo "command[check_disk_tmp]=$nrpe "${pt[$i]}"" >> $nrpe1

elif [ ${mnt[$i]} = "/usr" ]; then
echo "command[check_disk_usr]=$nrpe "${pt[$i]}"" >> $nrpe1

elif [ ${mnt[$i]} = "/backup" ]; then
echo "command[check_disk_backup]=$nrpe "${pt[$i]}"" >> $nrpe1

elif [ ${mnt[$i]} = "/boot" ]; then
echo "command[check_disk_boot]=$nrpe "${pt[$i]}"" >> $nrpe1

fi
done

#Adding other custom commands
echo "command[check_dovecot]=/usr/local/nagios/libexec/check_dovecot -d -i -p -w 100 -c 200" >> $nrpe1
echo "command[check_logfiles]=/usr/local/nagios/libexec/check_logfiles -f /usr/local/nagios/etc/exim_log.cfg" >> $nrpe1

#remove all files

#make symlink for perl

ln -s /usr/bin/perl /usr/local/bin/perl

#All done

echo "Cleaning up.."

rm -rf $rsin

rm -fv rsin.sh

#restarting service.

chkconfig xinetd on

service xinetd start

echo "All Done...Have a cup of Coffee after allowing port :P"

echo "Allow port 5666 in Firewall/CSF"
echo 
echo "DO NOT FORGET TO OPEN PORT"

echo "...."
echo "...."
echo "Thanks for using this scirpt!!"
echo "...."
echo "...."

rm -- "$0"
