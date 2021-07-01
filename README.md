# MysqlReplication

## 下载安装包 downloadrpm

可自行从官网下载，此安装包经CentOS7.6验证通过，执行部署脚本前需要先下载安装包

## 部署脚本 deployuMS

1. 请确保内网连通性
2. 配置两台服务器之间ssh免登
3. hosts文件做好解析
4. 必需使用root用户

## 手动切换主从 exchangeMS

手动切换mysql主从关系，目前只可手动切换一次

## 手动安装数据库 installmysql

若自动安装失败，可执行此脚本验证问题

## 手动卸载数据库 uninstallmysql

手动卸载Mysql，需要在两台服务器上分别进行。请注意卸载后原始数据会丢失，若为运行环境一定要做数据库备份！！

## 更改数据库密码 changepasswd

目前密码是固定的，若密码变动部署脚本会失效。若想安装时候再修改密码，至仍需重新配置主从关系。

