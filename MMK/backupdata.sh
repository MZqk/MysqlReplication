#!/bin/bash
source ~/.bash_profile #加载用户环境变量
#set -o nounset    #引用未初始化变量时退出
#set -o errexit   #执行shell命令遇到错误时退出

#备份用户---需要在mysql中提前创建并授权
#GRANT SELECT,RELOAD,LOCK TABLES,REPLICATION CLIENT,SHOW VIEW,TRIGGER,EVENT ON *.* TO 'backup'@'%' IDENTIFIED BY 'baifendian';
user="root"
#备份用户密码
password="mysql1qaz@WSX"
port="3306"
mysql_path="/usr/bin/mysql"
date=$(date +%Y-%m-%d_%H-%M-%S)
del_date=$(date +%Y-%m-%d)
#备份路径---需要修改
backup_path="/home/guandata/backup_data/mysql"
backup_log_path="/home/guandata/backup_data/mysql/log"
day=7
backup_log="/home/guandata/backup_data/mysql/log/mysqldump_backup_${date}.log"

#删除以前备份
find ${backup_path} -type f -mtime +$day -name "*.tar.gz" -exec rm -rf {} \; > /dev/null 2>&1 

for f in `ls $backup_path`;
do
  if [[ $f = ${del_date}_* ]]; then
    rm -rf $backup_path/$f
  fi
done

#建立备份目录
if [ ! -e $backup_path/${date} ];then
  mkdir -p {$backup_path/${date},$backup_log_path}
fi
 
 
#echo "开始备份所有数据库" 
echo "备份开始,结果查看 $backup_log"
echo "==========All databases backups begin==========" >>$backup_log
#备份并压缩
for dbname in $(mysql -P$port -u$user -p$password -A -e "show databases\G"|grep Database|grep -v schema|grep -v test|awk '{print $2}')
  do
  sleep 1
  mysqldump -P$port -u$user -p$password $dbname > $backup_path/${date}/$dbname.sql
  if [[ $? == 0 ]];then
    cd $backup_path/${date}
    size=$(du $backup_path/${date}/$dbname.sql -sh | awk '{print $1}')
    echo "备份时间:${date} 备份方式:mysqldump 备份数据库:$dbname($size) 备份状态:成功！" >>$backup_log
  else
    cd $backup_path/${date}
  echo "备份时间:${date} 备份方式:mysqldump 备份数据库:${dbname} 备份状态:失败,请查看日志." >>$backup_log
 fi
 
 done
 
cd $backup_path
tar zcpvf mysql_all_databases_$date.tar.gz $date
rm -rf $backup_path/$date

du mysql_all_databases_$date.tar.gz -sh | awk '{print "文件:" $2 ",大小:" $1}'
echo "==========All databases backups over==========" >>$backup_log
