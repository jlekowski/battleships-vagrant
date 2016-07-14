#!/bin/bash

# to avoid unknown host when sudo (not necessary for some vagrant boxes)
sed -i -e "s/localhost$/localhost $(hostname)/" /etc/hosts

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y vim mysql-server

mysql -e "CREATE DATABASE battleships CHARACTER SET = utf8mb4 COLLATE utf8mb4_unicode_ci"
mysql -e "GRANT SELECT ON battleships.* TO 'ubuntu'@'10.10.10.10' IDENTIFIED BY 'ubuntu'"
mysql -e "FLUSH PRIVILEGES"

sed -i -e "s/bind-address.*= 127.0.0.1/bind-address = $1/" /etc/mysql/mysql.conf.d/mysqld.cnf
echo "
server-id = 2
replicate-do-db = battleships
binlog-format = mixed
read-only = 1
" | tee -a /etc/mysql/mysql.conf.d/mysqld.cnf

service mysql restart

#SHOW SLAVE STATUS \G
#LOAD DATA FROM MASTER;
mysql -e "STOP SLAVE"
# this is "not pretty" to hardcode log file and pos here instead of getting from master
mysql -e "CHANGE MASTER TO MASTER_HOST='10.10.10.11', MASTER_USER='slave_user', MASTER_PASSWORD='slave', MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=154"
mysql -e "START SLAVE"
#SHOW SLAVE STATUS \G
