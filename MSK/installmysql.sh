#!/bin/bash

/bin/rpm -e $(/bin/rpm -qa | grep mariadb|xargs) --nodeps

rpm -ivh mysql-community-server-5.7.34-1.el7.x86_64.rpm mysql-community-common-5.7.34-1.el7.x86_64.rpm mysql-community-client-5.7.34-1.el7.x86_64.rpm mysql-community-libs-5.7.34-1.el7.x86_64.rpm mysql-community-libs-compat-5.7.34-1.el7.x86_64.rpm

systemctl start mysqld
systemctl stop mysqld
