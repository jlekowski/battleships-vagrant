#!/bin/bash

externalDbCount=$1
isDevEnv=$2
symfonyVarDir=$3
symfonyDevEnabled=$4

# Host config
echo "127.0.0.1 battleships-api.vagrant" | sudo tee -a /etc/hosts

# if not using external DBs, set up DB locally
if [ ! $externalDbCount ] || [ $externalDbCount -lt 1 ]; then
    # DB user
    sudo mysql -e "CREATE DATABASE battleships CHARACTER SET = utf8mb4 COLLATE utf8mb4_unicode_ci"
    if [ $isDevEnv ]; then
        mysqlHost=%
    else
        mysqlHost=127.0.0.1
    fi
    sudo mysql -e "GRANT ALL PRIVILEGES ON battleships.* TO 'ubuntu'@'$mysqlHost' IDENTIFIED BY 'ubuntu'"
    sudo mysql -e "FLUSH PRIVILEGES"
fi

# Symfony env vars
## for dev vm with shared files
if [ $symfonyVarDir ]; then
    # | as separator because of / in the variable
    sed -i -e "s|# fastcgi_param SYMFONY__VAR_DIR .*|fastcgi_param SYMFONY__VAR_DIR $symfonyVarDir;|" battleships-api
fi

## for dev vm to access app_dev.php
if [ $symfonyDevEnabled ]; then
    sed -i -e "s/# fastcgi_param SYMFONY__DEV_ENABLED .*/fastcgi_param SYMFONY__DEV_ENABLED 1;/" battleships-api
fi

# Web server config (file copied by Vagrant file provision)
sudo mv battleships-api /etc/nginx/sites-available/battleships-api
sudo ln -s /etc/nginx/sites-available/battleships-api /etc/nginx/sites-enabled
sudo service nginx reload

# Repo setup
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

    ## set folder permissions (http://symfony.com/doc/current/book/installation.html)
    bash ~/battleships-api-acl.sh $symfonyVarDir
    rm ~/battleships-api-acl.sh

    ## set parameters
    cp app/config/parameters.yml.dist app/config/parameters.yml
    # define master DB
    if [ $externalDbCount ] && [ $externalDbCount -gt 0 ]; then
        sed -i -e "s/database_host:.*/database_host: 10.10.10.11/" app/config/parameters.yml
    fi
    sed -i -e "s/database_user:.*/database_user: ubuntu/" app/config/parameters.yml
    sed -i -e "s/database_password:.*/database_password: ubuntu/" app/config/parameters.yml
    sed -i -e "s/loggly_token:.*/loggly_token: vagrantT0k3n/" app/config/parameters.yml
    sed -i -e "s/loggly_tag:.*/loggly_tag: battleships-api-vagrant/" app/config/parameters.yml
    if [ $isDevEnv ]; then
        sed -i -e "s/varnish_debug:.*/varnish_debug: true/" app/config/parameters.yml
    fi
    sed -i -e "s/varnish_enabled:.*/varnish_enabled: true/" app/config/parameters.yml
    sed -i -e "s/varnish_base_url:.*/varnish_base_url: battleships-api.vagrant/" app/config/parameters.yml
    # define slave DBs
    if [ $externalDbCount ] && [ $externalDbCount -gt 1 ]; then
        sed -i -e "/database_slaves: /d" app/config/parameters.yml
        slavesSettings="    database_slaves:"
        for i in $(seq 2 $externalDbCount); do
            slavesSettings+="
        slave$(($i - 1)):
            host:     10.10.10.1$i
            port:     ~
            dbname:   battleships
            user:     ubuntu
            password: ubuntu
"
        done
        printf '%s\n' "$slavesSettings" | tee -a app/config/parameters.yml
    fi

    ## install dependencies
    if [ $isDevEnv ]; then
        COMPOSER_CACHE_DIR=/vagrant/composer-cache composer install -n
    else
        echo "SYMFONY_ENV=prod" | tee -a ~/.bashrc
        export SYMFONY_ENV=prod
        COMPOSER_CACHE_DIR=/vagrant/composer-cache composer install -n --optimize-autoloader --no-dev
    fi
else
    ## set folder permissions (http://symfony.com/doc/current/book/installation.html)
    bash ~/battleships-api-acl.sh $symfonyVarDir
    rm ~/battleships-api-acl.sh
fi

## create tables
cd /var/www/battleships-api
bin/console doctrine:schema:update --force
