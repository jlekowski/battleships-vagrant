#!/bin/bash

# Host config
echo "127.0.0.1 battleships-api.vagrant" | sudo tee -a /etc/hosts

# DB user
sudo mysql -e "CREATE DATABASE battleships CHARACTER SET = utf8mb4 COLLATE utf8mb4_unicode_ci"
sudo mysql -e "GRANT ALL PRIVILEGES ON battleships.* TO 'ubuntu'@'127.0.0.1' IDENTIFIED BY 'ubuntu'"
sudo mysql -e "FLUSH PRIVILEGES"

# Web server config (file copied by Vagrant file provision)
sudo mv battleships-api /etc/nginx/sites-available/battleships-api
sudo ln -s /etc/nginx/sites-available/battleships-api /etc/nginx/sites-enabled
sudo service nginx reload

# Repo setup
## create folder
sudo mkdir /var/www/battleships-api
sudo chown $(whoami):$(whoami) /var/www/battleships-api
cd /var/www/battleships-api

## clone repo
git clone https://github.com/jlekowski/battleships-api.git .
git remote set-url origin git@github.com:jlekowski/battleships-api.git

## set folder permissions (http://symfony.com/doc/current/book/installation.html)
HTTPDUSER=`ps axo user,comm | grep -E '[a]pache|[h]ttpd|[_]www|[w]ww-data|[n]ginx' | grep -v root | head -1 | cut -d\  -f1`
sudo setfacl -R -m u:"$HTTPDUSER":rwX -m u:`whoami`:rwX var
sudo setfacl -dR -m u:"$HTTPDUSER":rwX -m u:`whoami`:rwX var

## set parameters
cp app/config/parameters.yml.dist app/config/parameters.yml
sed -i -e "s/database_user:.*/database_user: ubuntu/" app/config/parameters.yml
sed -i -e "s/database_password:.*/database_password: ubuntu/" app/config/parameters.yml
sed -i -e "s/loggly_token:.*/loggly_token: vagrantT0k3n/" app/config/parameters.yml
sed -i -e "s/loggly_tag:.*/loggly_tag: battleships-api-vagrant/" app/config/parameters.yml
sed -i -e "s/varnish_debug:.*/varnish_debug: true/" app/config/parameters.yml
sed -i -e "s/varnish_enabled:.*/varnish_enabled: true/" app/config/parameters.yml
sed -i -e "s/varnish_base_url:.*/varnish_base_url: battleships-api.vagrant/" app/config/parameters.yml
echo "
    database_slaves:
        slave1:
            host:     \"10.10.10.12\"
            port:     \"%database_port%\"
            dbname:   \"%database_name%\"
            user:     \"%database_user%\"
            password: \"%database_password%\"
" | tee -a app/config/parameters.yml

## install dependencies
composer install -n

## create tables
bin/console doctrine:schema:update --force
