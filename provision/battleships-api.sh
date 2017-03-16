#!/bin/bash

isDevEnv=$1;
symfonyVarDir=$2
symfonyDevEnabled=$3

# Host config
echo "127.0.0.1 battleships-api.vagrant" | sudo tee -a /etc/hosts

# DB user
sudo mysql -e "CREATE DATABASE battleships CHARACTER SET = utf8mb4 COLLATE utf8mb4_unicode_ci"
if [ $isDevEnv ]; then
    mysqlHost=%
else
    mysqlHost=127.0.0.1
fi
sudo mysql -e "GRANT ALL PRIVILEGES ON battleships.* TO 'ubuntu'@'$mysqlHost' IDENTIFIED BY 'ubuntu'"
sudo mysql -e "FLUSH PRIVILEGES"

# Symfony env vars
## for dev vm with shared files
if [ $symfonyVarDir ]; then
    # | as separator because of / in the variable
    sed -i -e "s|# fastcgi_param SYMFONY__VAR_DIR .*|fastcgi_param SYMFONY__VAR_DIR $symfonyVarDir|" battleships-api
fi

## for dev vm to access app_dev.php
if [ $symfonyDevEnabled ]; then
    sed -i -e "s/# fastcgi_param SYMFONY__DEV_ENABLED .*/fastcgi_param SYMFONY__DEV_ENABLED 1/" battleships-api
fi

# Web server config (file copied by Vagrant file provision)
sudo mv battleships-api /etc/nginx/sites-available/battleships-api
sudo ln -s /etc/nginx/sites-available/battleships-api /etc/nginx/sites-enabled
sudo service nginx reload

# Repo setup
## set folder permissions (http://symfony.com/doc/current/book/installation.html)
if [ $isDevEnv ]; then
    varDir=/tmp/var
    mkdir $varDir
else
    varDir=var
fi
HTTPDUSER=`ps axo user,comm | grep -E '[a]pache|[h]ttpd|[_]www|[w]ww-data|[n]ginx' | grep -v root | head -1 | cut -d\  -f1`
sudo setfacl -R -m u:"$HTTPDUSER":rwX -m u:`whoami`:rwX $varDir
sudo setfacl -dR -m u:"$HTTPDUSER":rwX -m u:`whoami`:rwX $varDir

# if not dev, or dev but no folder
if [ ! $isDevEnv ] || [ ! -d /var/www/battleships-api ]; then
    ## create folder
    sudo mkdir /var/www/battleships-api
    sudo chown $(whoami):$(whoami) /var/www/battleships-api
    cd /var/www/battleships-api

    ## clone repo
    git clone https://github.com/jlekowski/battleships-api.git .
    git remote set-url origin git@github.com:jlekowski/battleships-api.git
    if [ $isDevEnv ]; then
        git checkout develop
    fi

    ## set parameters
    cp app/config/parameters.yml.dist app/config/parameters.yml
    sed -i -e "s/database_user:.*/database_user: ubuntu/" app/config/parameters.yml
    sed -i -e "s/database_password:.*/database_password: ubuntu/" app/config/parameters.yml
    sed -i -e "s/loggly_token:.*/loggly_token: vagrantT0k3n/" app/config/parameters.yml
    sed -i -e "s/loggly_tag:.*/loggly_tag: battleships-api-vagrant/" app/config/parameters.yml
    if [ $isDevEnv ]; then
        sed -i -e "s/varnish_debug:.*/varnish_debug: true/" app/config/parameters.yml
    else
        sed -i -e "s/varnish_debug:.*/varnish_debug: false/" app/config/parameters.yml
    fi
    sed -i -e "s/varnish_enabled:.*/varnish_enabled: true/" app/config/parameters.yml
    sed -i -e "s/varnish_base_url:.*/varnish_base_url: battleships-api.vagrant/" app/config/parameters.yml
#    echo "
#    database_slaves:
#        slave1:
#            host:     \"10.10.10.12\"
#            port:     \"%database_port%\"
#            dbname:   \"%database_name%\"
#            user:     \"%database_user%\"
#            password: \"%database_password%\"
#" | tee -a app/config/parameters.yml

    ## install dependencies
    composer install -n
else
    cd /var/www/battleships-api
fi

## create tables
bin/console doctrine:schema:update --force
