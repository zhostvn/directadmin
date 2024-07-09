#!/bin/bash
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
       cd /usr/local/directadmin/scripts
        ./ipswap.sh $IPold $ip_addr
        systemctl restart pure-ftpd
        systemctl restart exim
        systemctl restart dovecot

        #chown -R diradmin:diradmin /usr/local/directadmin/data/admin/ips
        cd /usr/local/directadmin/custombuild
        ./build rewrite_confs
        #./build update
        #./build update_versions
        
        #Update DA KEY
        service directadmin stop
        rm -rf /usr/local/directadmin/conf/license.key
        wget -O /usr/local/directadmin/conf/license.key https://mirrors.trunglab.com/license/license.key
        chmod 600 /usr/local/directadmin/conf/license.key
        chown diradmin:diradmin /usr/local/directadmin/conf/license.key
        chattr +i /usr/local/directadmin/conf/license.key
        

        # restart service
        systemctl daemon-reload
        service directadmin restart
        systemctl restart pure-ftpd.service
        systemctl restart litespeed

        # delete log
        cd /var/log/directadmin/
        rm -rf *
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
