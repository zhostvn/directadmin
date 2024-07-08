#!/bin/bash
yum install crudini -y
#create random password for admin user
passwd_admin=`date +%s | sha256sum | base64 | head -c 12`

IPglobal=`ip addr | grep "24 scope global lo" | head -1 | awk '{ print $2 }'`

#Get IP old
IPold=`cat /usr/local/directadmin/data/users/admin/ip.list`

#Get IP address
ip_addr=`ifconfig | grep netmask | awk 'NR==1{print $2}'`

#Change DirectAdmin admin password
echo "$passwd_admin" | passwd --stdin admin

#Change Main IP

if [ $IPold != $ip_addr ]
then
        /usr/local/directadmin/scripts/ipswap.sh $IPold $ip_addr
        chown -R diradmin:diradmin /usr/local/directadmin/data/admin/ips
        cd /usr/local/directadmin/custombuild
        ./build update
        ./build update_versions

        #Update DA KEY
        systemctl daemon-reload
        wget -O /usr/local/directadmin/conf/license.key https://github.com/zhostvn/directadmin/raw/main/license.key > /dev/null 2>&1
        chmod 600 /usr/local/directadmin/conf/license.key
        chown diradmin:diradmin /usr/local/directadmin/conf/license.key

        # restart service
        systemctl restart pure-ftpd.service
        systemctl restart litespeed

        # delete log
        cd /var/log/directadmin/
        rm -rf *
fi

#Update information
crudini --set /usr/local/directadmin/scripts/setup.txt DEFAULT adminpass $passwd_admin
crudini --set /usr/local/directadmin/scripts/setup.txt DEFAULT ip $ip_addr

ip addr | grep "24 scope global lo" >> /dev/null 2>&1
if [ $? == 0 ]; then
        ip addr del $IPglobal dev lo
fi
#Create Guide text file
clear
rm -rf /root/DirectAdmin_information.txt
touch /root/DirectAdmin_information.txt

echo "

=============================================================

Thong tin quan tri DirectAdmin cua ban nhu sau:

Login_link              : http://$ip_addr:2222
User_name               : admin
Password                : $passwd_admin

=============================================================

CAM ON BAN DA SU DUNG DICH VU TAI ZHOST

THONG TIN SE DUOC LUU TAI FILE DirectAdmin_information.txt
=============================================================
" >> /root/DirectAdmin_information.txt

cat /root/DirectAdmin_information.txt
