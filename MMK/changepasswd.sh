#!/bin/bash

echo "Getting Mysql root Initial password"
systemctl start mysqld

Mysqlroot=`cat /var/log/mysqld.log |grep password|grep temporary|awk '{print $11}'`
echo "mysql -uroot -p'${Mysqlroot}'"

echo "Change Mysql root password"
mysql -uroot -p$Mysqlroot --connect-expired-password  <<< "set password for root@localhost = password('mysql1qaz@WSX');"
mysql -uroot -pmysql1qaz@WSX  <<< "update mysql.user set host='%' where host='localhost' and user='root';"
systemctl restart mysql