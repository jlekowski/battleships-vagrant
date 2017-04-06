#!/bin/bash

# Repo setup
## create folder
sudo mkdir /var/www/battleships-apiclient
sudo chown $(whoami):$(whoami) /var/www/battleships-apiclient
cd /var/www/battleships-apiclient

## clone repo
git clone https://github.com/jlekowski/battleships-apiclient.git .
git remote set-url origin git@github.com:jlekowski/battleships-apiclient.git

## install dependencies
COMPOSER_CACHE_DIR=/vagrant/composer-cache composer install -n --optimize-autoloader --no-dev
