#!/bin/bash

dbId=$1 # 1 for master, 2,3,4... for slaves
dbIpAddress=$2
webIpAddress=$3
enableLogging=$4

# to avoid unknown host when sudo (not necessary for some vagrant boxes)
sed -i -e "s/localhost$/localhost $(hostname)/" /etc/hosts

export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y vim mysql-server

mysql -e "CREATE DATABASE battleships CHARACTER SET = utf8mb4 COLLATE utf8mb4_unicode_ci"
if [ $dbId -eq 1 ]; then
    mysql -e "GRANT ALL PRIVILEGES ON battleships.* TO 'ubuntu'@'$webIpAddress' IDENTIFIED BY 'ubuntu'"
    mysql -e "GRANT REPLICATION SLAVE ON *.* TO 'slave_user'@'%' IDENTIFIED BY 'slave'"
else
    mysql -e "GRANT SELECT ON battleships.* TO 'ubuntu'@'$webIpAddress' IDENTIFIED BY 'ubuntu'"
fi
mysql -e "FLUSH PRIVILEGES"

sed -i -e "s/bind-address.*= 127.0.0.1/bind-address = $dbIpAddress/" /etc/mysql/mysql.conf.d/mysqld.cnf
if [ $enableLogging ]; then
    sed -i -e "s/#general_log/general_log/" /etc/mysql/mysql.conf.d/mysqld.cnf
fi

if [ $dbId -eq 1 ]; then
    echo "
server-id = $dbId
log_bin = /var/log/mysql/mysql-bin.log
binlog_do_db = battleships
" | tee -a /etc/mysql/mysql.conf.d/mysqld.cnf
else
    echo "
server-id = $dbId
replicate-do-db = battleships
binlog-format = mixed
read-only = 1
" | tee -a /etc/mysql/mysql.conf.d/mysqld.cnf
fi

service mysql restart

if [ $dbId -gt 1 ]; then
    mysql -e "STOP SLAVE"
    # this is "not pretty" to hardcode log file and pos here instead of getting from master
    mysql -e "CHANGE MASTER TO MASTER_HOST='10.10.10.11', MASTER_USER='slave_user', MASTER_PASSWORD='slave', MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=154"
    mysql -e "START SLAVE"
fi
