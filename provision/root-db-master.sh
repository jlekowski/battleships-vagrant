#!/bin/bash

# to avoid unknown host when sudo (not necessary for some vagrant boxes)
sed -i -e "s/localhost$/localhost $(hostname)/" /etc/hosts

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y vim mysql-server

mysql -e "CREATE DATABASE battleships CHARACTER SET = utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER 'ubuntu'@'10.10.10.10' IDENTIFIED BY 'ubuntu'";
mysql -e "GRANT ALL PRIVILEGES ON battleships.* TO 'ubuntu'@'10.10.10.10' WITH GRANT OPTION";
mysql -e "FLUSH PRIVILEGES";

sed -i -e "s/bind-address.*= 127.0.0.1/bind-address = 10.10.10.11/" /etc/mysql/mysql.conf.d/mysqld.cnf
service mysql restart
