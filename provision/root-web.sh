#!/bin/bash

isDevEnv=$1

# to avoid unknown host when sudo (not necessary for some vagrant boxes)
#sed -i -e "s/localhost$/localhost $(hostname)/" /etc/hosts

export DEBIAN_FRONTEND=noninteractive
add-apt-repository ppa:ondrej/php -y
apt update
# install php-fpm first to avoid installing apache
apt install -y php-fpm
apt install -y git vim nginx varnish php php-xml php-mysql php-curl php-dev php-intl php-apcu php-xdebug php-phpdbg unzip acl

if [ $isDevEnv ]; then
    apt install -y mysql-server php-mbstring
    # support for folder sharing on Windows
    #apt install -y virtualbox-guest-dkms
fi

# Enable OPCache
echo "
opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.validate_timestamps = 1
opcache.revalidate_freq = 60
opcache.revalidate_path = 1
opcache.save_comments = 1
opcache.fast_shutdown = 1
opcache.enable_file_override = 1
" | tee -a /etc/php/7.1/fpm/php.ini

echo "
opcache.enable_cli = 1

apc.enable_cli = 1
" | tee -a /etc/php/7.1/cli/php.ini /etc/php/7.1/phpdbg/php.ini

if [ $isDevEnv ]; then
    # Enable Xdebug
    echo "
xdebug.remote_enable = 1
xdebug.idekey = "PHPSTORM"
xdebug.overload_var_dump = 0
xdebug.remote_connect_back = 1
" | tee -a /etc/php/7.1/fpm/php.ini /etc/php/7.1/cli/php.ini
fi

service php7.1-fpm restart

# Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Web server to listen on port 8080
sed -i -e "s/80 default_server/8080 default_server/" /etc/nginx/sites-available/default
service nginx restart

# Varnish config
mv battleships-api.vcl /etc/varnish/battleships-api.vcl
echo '
DAEMON_OPTS="-a :80 \
             -T localhost:6082 \
             -f /etc/varnish/battleships-api.vcl \
             -S /etc/varnish/secret \
             -s malloc,256m"
' | tee -a /etc/default/varnish
sed -i -e "s/:6081/:80/" /lib/systemd/system/varnish.service
sed -i -e "s/default.vcl/battleships-api.vcl/" /lib/systemd/system/varnish.service
ln -s /lib/systemd/system/varnish.service /etc/systemd/system/varnish.service
systemctl reload varnish.service
systemctl daemon-reload
service varnish restart

if [ $isDevEnv ]; then
    sed -i -e "s/#general_log/general_log/" /etc/mysql/mysql.conf.d/mysqld.cnf
    sed -i -e "s/bind-address/#bind-address/" /etc/mysql/mysql.conf.d/mysqld.cnf
    service mysql restart
fi
