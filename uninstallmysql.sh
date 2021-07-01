#! /bin/bash

systemctl stop mysqld 

#/bin/rpm -e $(/bin/rpm -qa | grep mysql|xargs) --nodeps
yum remove -y mysql-community-server-5.7.34-1.el7.x86_64 mysql-community-common-5.7.34-1.el7.x86_64 mysql-community-client-5.7.34-1.el7.x86_64 mysql-community-libs-5.7.34-1.el7.x86_64 mysql-community-libs-compat-5.7.34-1.el7.x86_64 

rm -rf /var/lib/mysql
rm -rf /etc/my.conf
rm -rf /var/log/mysql*
