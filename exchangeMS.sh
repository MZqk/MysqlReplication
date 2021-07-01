!/bin/bash
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
    echo "Error: Input Slave IP and Hostname not\‘s match"
    exit 1
fi

# Check if user is root
if [ $UID -ne 0 ]; then
 echo "Error: You must be root to run this script, please use root to install"
 exit 1
fi

echo "Check MS sync status"
echo "============================================"
mysql -uroot -pmysql1qaz@WSX <<< "flush tables with read lock;"
#while [[ `mysql -uroot -pmysql1qaz@WSX <<< "show processlist;"|grep "waiting for more updates"" ]]
#do
#    echo "MS still synching data waiting"
#    sleep 5 
#done
echo "MS data synching  completed  "

echo "Change Slave to Master"
echo "============================================"
ssh ${SlaveName} "mysql -uroot -pmysql1qaz@WSX <<EOF
CREATE USER 'guandatadb_slave'@'%' IDENTIFIED BY 'mysql1qaz@WSX';
GRANT REPLICATION SLAVE ON *.* TO 'guandatadb_slave'@'%' identified by 'mysql1qaz@WSX';
flush privileges;
Stop slave;
Reset master;
Reset slave all;
EOF
"

echo "Getting the Master\'s Binary Log Co-ordinates"
echo "============================================"
#Mbinlog=`ssh ${SlaveName} \"mysql -uroot -pmysql1qaz@WSX -e "SHOW MASTER STATUS;"|tail -n 1"|awk '{print $1}'`
#Mpos=`ssh ${SlaveName} \"mysql -uroot -pmysql1qaz@WSX -e "SHOW MASTER STATUS;"|tail -n 1"|awk '{print $2}'`
Mbinlog=`ssh ${SlaveName} "mysql -uroot -pmysql1qaz@WSX -e \"SHOW MASTER STATUS;\"|tail -n 1"|awk '{print $1}'`
Mpos=`ssh ${SlaveName} "mysql -uroot -pmysql1qaz@WSX -e \"SHOW MASTER STATUS;\"|tail -n 1 "| awk '{print $2}'`

echo Mbinlog:${Mbinlog} 
echo Mpos:${Mpos}

echo "Change Master to Slave"
echo "============================================"
mysql -uroot -pmysql1qaz@WSX <<EOF
CHANGE MASTER TO
  MASTER_HOST='${SlaveIP}',
  MASTER_USER='guandatadb_slave',
  MASTER_PASSWORD='mysql1qaz@WSX',
  MASTER_PORT=3306,
  MASTER_LOG_FILE='${Mbinlog}',
  MASTER_LOG_POS=${Mpos},
  MASTER_CONNECT_RETRY=10;
START SLAVE;
unlock tables;
EOF


echo "Check that the replication is working"
echo "============================================"
Slaveready=`mysql -uroot -pmysql1qaz@WSX <<< "show slave status\G;"|grep -E Slave.*Running:|grep Yes |wc -l`
if [ $Slaveready -eq 2 ]
then
    echo "Slave is ready"
else
    echo "Slave is falied"
fi
