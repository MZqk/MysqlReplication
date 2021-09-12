#!/bin/bash

ipwithmask=`ip addr |grep -A2 BROADCAST,MULTICAST,UP,LOWER_UP|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"|sed -n 1p`
MACHINEIP=${ipwithmask%/*}
echo "Detected IP:"
echo ${MACHINEIP}

echo "!!! Note that you must to be configure Master and Slave of ssh no password login"
read -p "Please input Slave Machine IP:" SlaveIP
read -p "Please input Slave Machine hostname:" SlaveName
if (cat /etc/hosts | grep ${SlaveIP}|grep ${SlaveName})
then 
    echo "Slave hostnmae:" ${SlaveName}
else
    echo "Error: You need set /etc/hosts your's Slave IP and Hostname"
    exit 1
fi

# Check if user is root
if [ $UID -ne 0 ]; then
 echo "Error: You must be root to run this script, please use root to install"
 exit 1
fi

echo "Staring install Mysql5.7 soft"
echo "============================================"
bash ./installmysql.sh 2>&1 >/dev/null
bash changedatadir.sh
cat mysql.param > /etc/my.cnf
echo -e "server_id=1" >> /etc/my.cnf

echo "Configuring the Master"
echo "============================================"
# change init mysql password
bash ./changepasswd.sh 2>&1 >/dev/null
mysql -uroot -pmysql1qaz@WSX <<EOF
use mysql;
CREATE USER 'guandatadb_slave'@'%' IDENTIFIED BY 'mysql1qaz@WSX';
GRANT REPLICATION SLAVE ON *.* TO 'guandatadb_slave'@'%' identified by 'mysql1qaz@WSX';
flush privileges;
EOF


echo "Getting the Master's Binary Log Co-ordinates"
echo "============================================"
Mbinlog=`mysql -uroot -pmysql1qaz@WSX <<< "SHOW MASTER STATUS;"|tail -n 1|awk '{print $1}'`
Mpos=`mysql -uroot -pmysql1qaz@WSX <<< "SHOW MASTER STATUS;"|tail -n 1|awk '{print $2}'`
echo  ${Mbinlog} ${Mpos}


echo "Staring install Mysql5.7 soft for Slave"
echo "============================================"
ssh ${SlaveName} "cd /root;mkdir mysqlslave" 2>&1 >/dev/null 
rsync -u *rpm root@${SlaveName}:/root/mysqlslave 2>&1 >/dev/null
rsync -u * root@${SlaveName}:/root/mysqlslave 2>&1 >/dev/null
ssh ${SlaveName} "cd /root/mysqlslave;/bin/bash installmysql.sh;/bin/bash changedatadir.sh;cat mysql.param > /etc/my.cnf" 2>&1 >/dev/null 
ssh ${SlaveName} "echo -e \"server_id=2\nread_only=1\" >> /etc/my.cnf"

echo "Configuring the Slave"
echo "============================================"
ssh ${SlaveName} "cd /root/mysqlslave ;bash changepasswd.sh" 2>&1 >/dev/null
ssh ${SlaveName} "mysql -uroot -pmysql1qaz@WSX <<EOF
CHANGE MASTER TO
  MASTER_HOST='${MACHINEIP}',
  MASTER_USER='guandatadb_slave',
  MASTER_PASSWORD='mysql1qaz@WSX',
  MASTER_PORT=3306,
  MASTER_LOG_FILE='${Mbinlog}',
  MASTER_LOG_POS=${Mpos},
  MASTER_CONNECT_RETRY=10;
START SLAVE;
EOF
"

echo "Check that the replication is working"
echo "============================================"
sleep 3
Slaveready=`ssh ${SlaveName} "mysql -uroot -pmysql1qaz@WSX <<< \"show slave status\G;\"|grep -E Slave.*Running:|grep Yes |wc -l"`
if [ $Slaveready -eq 2 ]
then
    echo "Slave is ready"
else
    echo "Slave is falied"
fi
