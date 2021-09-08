#!/bin/bash

ipwithmask=`ip addr |grep -A2 BROADCAST,MULTICAST,UP,LOWER_UP|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"|sed -n 1p`
Master1IP=${ipwithmask%/*}
echo "Detected IP:"
echo ${Master1IP}

echo "!!! Note that you must to be configure Master1 and Master2 of ssh no password login"
read -p "Please input Master2 Machine IP:" Master2IP
read -p "Please input Master2 Machine hostname:" Master2Name
if (cat /etc/hosts | grep ${Master2IP}|grep ${Master2Name})
then 
    echo "Master2 hostnmae:" ${Master2Name}
else
    echo "Error: You need set /etc/hosts your's Master2 IP and Hostname"
    exit 1
fi
# Check if user is root
if [ $UID -ne 0 ]; then
 echo "Error: You must be root to run this script, please use root to install"
 exit 1
fi

echo "Staring install Mysql5.7 soft for Master1"
echo "============================================"
bash ./installmysql.sh 2>&1 >/dev/null
echo -e "log-bin\nserver_id=1\ncharacter-set-server=utf8mb4" >> /etc/my.cnf
#cat mysql.param >> /etc/my.cnf
# change init mysql password
bash ./changepasswd.sh 2>&1 >/dev/null

echo "Staring install Mysql5.7 soft for Master2"
echo "============================================"
ssh ${Master2Name} "cd /root;mkdir mysqlmaster2" 2>&1 >/dev/null 
rsync -u *rpm root@${Master2Name}:/root/mysqlmaster2 2>&1 >/dev/null
rsync -u *sh root@${Master2Name}:/root/mysqlmaster2 2>&1 >/dev/null
ssh ${Master2Name} "cd /root/mysqlmaster2;/bin/bash installmysql.sh" 2>&1 >/dev/null 
ssh ${Master2Name} "echo -e \"server_id=2\nlog-bin\ncharacter-set-server=utf8mb4\" >> /etc/my.cnf"
# change init mysql password
ssh ${Master2Name} "cd /root/mysqlmaster2 ;bash changepasswd.sh" 2>&1 >/dev/null

echo "Getting the Master1's Binary Log Co-ordinates"
echo "============================================"
Mbinlog1=`mysql -uroot -pmysql1qaz@WSX <<< "SHOW MASTER STATUS;"|tail -n 1|awk '{print $1}'`
Mpos1=`mysql -uroot -pmysql1qaz@WSX <<< "SHOW MASTER STATUS;"|tail -n 1|awk '{print $2}'`
echo  ${Mbinlog1} ${Mpos1}
echo "Getting the Master2's Binary Log Co-ordinates"
echo "============================================"
Mbinlog2=`ssh ${Master2Name} "mysql -uroot -pmysql1qaz@WSX <<< \"SHOW MASTER STATUS;\"|tail -n 1|awk '{print $1}'"`
Mpos2=`ssh ${Master2Name} "mysql -uroot -pmysql1qaz@WSX <<< \"SHOW MASTER STATUS;\"|tail -n 1|awk '{print $2}'"`
echo  ${Mbinlog2} ${Mpos2}

echo "Configuring the Master1"
echo "============================================"
mysql -uroot -pmysql1qaz@WSX <<EOF
use mysql;
CHANGE MASTER TO
  MASTER_HOST='${Master2IP}',
  MASTER_USER='guandatadb_slave',
  MASTER_PASSWORD='mysql1qaz@WSX',
  MASTER_PORT=3306,
  MASTER_LOG_FILE='${Mbinlog2}',
  MASTER_LOG_POS=${Mpos2},
  MASTER_CONNECT_RETRY=10;
START SLAVE;
EOF

echo "Configuring the Master2"
echo "============================================"
ssh ${Master2Name} "mysql -uroot -pmysql1qaz@WSX <<EOF
use mysql;
CHANGE MASTER TO
  MASTER_HOST='${Master1IP}',
  MASTER_USER='guandatadb_slave',
  MASTER_PASSWORD='mysql1qaz@WSX',
  MASTER_PORT=3306,
  MASTER_LOG_FILE='${Mbinlog1}',
  MASTER_LOG_POS=${Mpos1},
  MASTER_CONNECT_RETRY=10;
START SLAVE;
EOF
"

echo "Check that the replication is working"
echo "============================================"
sleep 3
Slaveready=`mysql -uroot -pmysql1qaz@WSX <<< "show slave status\G;"|grep -E Slave.*Running:|grep Yes |wc -l`
if [ $Slaveready -eq 2 ]
then
    echo "Master1 is ready"
else
    echo "Master1 is falied"
fi
echo "============================================"
sleep 3
Slaveready=`ssh ${Master2Name} "mysql -uroot -pmysql1qaz@WSX <<< \"show slave status\G;\"|grep -E Slave.*Running:|grep Yes |wc -l"`
if [ $Slaveready -eq 2 ]
then
    echo "Master2 is ready"
else
    echo "Master2 is falied"
fi
