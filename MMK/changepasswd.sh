#!/bin/bash

echo "Getting Mysql root Initial password"
systemctl start mysqld

Mysqlroot=`cat /var/log/mysqld.log |grep password|grep temporary|awk '{print $11}'`
echo "mysql -uroot -p'${Mysqlroot}'"

echo "Change Mysql root password"
mysql -uroot -p$Mysqlroot --connect-expired-password  <<< "set password for root@localhost = password('mysql1qaz@WSX');"
mysql -uroot -pmysql1qaz@WSX  <<< "update mysql.user set host='%' where host='localhost' and user='root';"

mysql -uroot -pmysql1qaz@WSX <<EOF
install plugin rpl_semi_sync_master soname 'semisync_master.so';
install plugin rpl_semi_sync_slave soname 'semisync_slave.so';
use mysql;
CREATE USER 'guandatadb_slave'@'%' IDENTIFIED BY 'mysql1qaz@WSX';
GRANT REPLICATION SLAVE ON *.* TO 'guandatadb_slave'@'%' identified by 'mysql1qaz@WSX';
EOF
systemctl restart mysqld