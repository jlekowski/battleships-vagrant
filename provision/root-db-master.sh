#!/bin/bash

ipAddress=$1;
enableLogging=$2

# to avoid unknown host when sudo (not necessary for some vagrant boxes)
sed -i -e "s/localhost$/localhost $(hostname)/" /etc/hosts

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y vim mysql-server

mysql -e "CREATE DATABASE battleships CHARACTER SET = utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "GRANT ALL PRIVILEGES ON battleships.* TO 'ubuntu'@'10.10.10.10' IDENTIFIED BY 'ubuntu'";
mysql -e "GRANT REPLICATION SLAVE ON *.* TO 'slave_user'@'%' IDENTIFIED BY 'slave'"
mysql -e "FLUSH PRIVILEGES";

sed -i -e "s/bind-address.*= 127.0.0.1/bind-address = $ipAddress/" /etc/mysql/mysql.conf.d/mysqld.cnf
if [ $enableLogging ]; then
    sed -i -e "s/#general_log/general_log/" /etc/mysql/mysql.conf.d/mysqld.cnf
fi
echo "
server-id = 1
log_bin = /var/log/mysql/mysql-bin.log
binlog_do_db = battleships
" | tee -a /etc/mysql/mysql.conf.d/mysqld.cnf

service mysql restart
