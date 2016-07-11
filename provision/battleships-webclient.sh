#!/bin/bash

# Web server config (file copied by Vagrant file provision)
sudo mv battleships-webclient /etc/nginx/sites-available/battleships-webclient
sudo ln -s /etc/nginx/sites-available/battleships-webclient /etc/nginx/sites-enabled
sudo service nginx reload

# Repo setup
## create folder
sudo mkdir /var/www/battleships-webclient
sudo chown $(whoami):$(whoami) /var/www/battleships-webclient
cd /var/www/battleships-webclient

## clone repo
git clone https://github.com/jlekowski/battleships-webclient.git .
git remote set-url origin git@github.com:jlekowski/battleships-webclient.git

## set parameters
sed -i -e "s/dev.lekowski.pl/vagrant/" web/js/main.js
