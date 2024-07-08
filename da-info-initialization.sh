#!/bin/bash
#create random password for admin user
passwd_admin=`date +%s | sha256sum | base64 | head -c 12`

IPglobal=`ip addr | grep "24 scope global lo" | head -1 | awk '{ print $2 }'`

#Get IP old
IPold=`cat /usr/local/directadmin/data/users/admin/ip.list`

#Get IP address
ip_addr=`ifconfig | grep netmask | awk 'NR==1{print $2}'`

#create random password for da_admin
passwd_da_admin=`pwgen -scn 12 1`

#Change Mysql pass
if [ -f /root/.my.cnf ]; then
chattr -i /root/.my.cnf
/usr/bin/mysqladmin -u da_admin password $passwd_da_admin
        if [ $? != 0 ]; then
                # Kill any mysql processes currently running
                service mysqld stop
                sleep 3
                killall -vw mysqld

                # Start mysql without grant tables
                mysqld_safe --skip-grant-tables >res 2>&1 &
                sleep 3

                # Update da_admin user with new password
                mysql mysql -e "UPDATE user SET Password=PASSWORD('$passwd_da_admin') WHERE User='da_admin';FLUSH PRIVILEGES;"

                # Kill the insecure mysql process
                killall -v mysqld
                sleep 3
                service mysqld start
        fi
else
        # Kill any mysql processes currently running
        service mysqld stop
        sleep 3
        killall -vw mysqld

        # Start mysql without grant tables
        mysqld_safe --skip-grant-tables >res 2>&1 &
        sleep 3

        # Update da_admin user with new password
        mysql mysql -e "UPDATE user SET Password=PASSWORD('$passwd_da_admin') WHERE User='da_admin';FLUSH PRIVILEGES;"

        # Kill the insecure mysql process
        killall -v mysqld
        sleep 3
                service mysqld start
fi
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

        # restart service
        systemctl restart pure-ftpd.service
        systemctl restart litespeed

        # delete log
        cd /var/log/directadmin/
        rm -rf *
fi

#Update information
crudini --set /usr/local/directadmin/scripts/setup.txt DEFAULT adminpass $passwd_admin
crudini --set /usr/local/directadmin/scripts/setup.txt DEFAULT mysql $passwd_da_admin
crudini --set /usr/local/directadmin/scripts/setup.txt DEFAULT ip $ip_addr
crudini --set /usr/local/directadmin/conf/my.cnf client password $passwd_da_admin
crudini --set /root/.my.cnf client password $passwd_da_admin
chattr +i /root/.my.cnf
sed -i 's/pass=/'pass=$passwd_da_admin'/g' /root/.mytop
chattr +i /root/.mytop
echo "user=da_admin
passwd=$passwd_da_admin" > /usr/local/directadmin/conf/mysql.conf

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
Login_mysql             : http://$ip_addr/phpmyadmin/
Mysql user              : da_admin
Mysql passwd            : $passwd_da_admin

=============================================================

CAM ON BAN DA SU DUNG DICH VU TAI ZHOST

THONG TIN SE DUOC LUU TAI FILE DirectAdmin_information.txt
=============================================================
" >> /root/DirectAdmin_information.txt

cat /root/DirectAdmin_information.txt
