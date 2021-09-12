#!/bin/bash
datadir=`cat mysql.param |grep datadir|awk -F '=' '{print $2}'`
if [ -e $datadir ] 
then
  echo "mysql data directory exists"
else
  mkdir -p $datadir
  echo "create mysql data directory "
fi
mv /var/lib/mysql $datadir
