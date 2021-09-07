Mbinlog=`ssh ha2 "mysql -uroot -pmysql1qaz@WSX -e \"SHOW MASTER STATUS;\"|tail -n 1"|awk '{print $1}'`
Mpos=`ssh ha2 "mysql -uroot -pmysql1qaz@WSX -e \"SHOW MASTER STATUS;\"|tail -n 1 "| awk '{print $2}'`
echo $Mbinlog $Mpos
