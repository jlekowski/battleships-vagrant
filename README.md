# Battleships (Vagrant)

## Battleships (sea battle) game - Vagrant settings
Vagrant setup to run and develop Battleships.

### LINKS
* https://github.com/jlekowski/battleships-api - API
* https://github.com/jlekowski/battleships-webclient - web client for the API
* https://github.com/jlekowski/battleships-apiclient - PHP client for the API

## === Installation ===
1. Install Vagrant (https://www.vagrantup.com)
2. Download and unzip or clone repository.
3. Run
```
vagrant up
# or to set up GIT with your name and email
VAGRANT_NAME='John Doe' VAGRANT_EMAIL='john@example.org' vagrant up
```
4. To log in to the VM
```
vagrant ssh
```
5. To access Web Client/API from the host machine add to your hosts file
```
10.10.10.10 battleships-api.vagrant
10.10.10.10 battleships-webclient.vagrant
```

## === Changelog ===
* version **1.0**
 * Working version with API (full server config), Web Client, API Client
 * Some improvements around Windows/Linux host machine config and folder sync required

## === Helpful commands ===
Dependencies security check (battleships-api folder)
```
bin/console security:check
```

Clear Symfony cache, OPCache, APC cache (battleships-api folder)
```
bin/console cache:clear --env=prod
sudo service php7.0-fpm reload
bin/console cache:apc:clear
```

Check ports used by web server, Varnish etc.
```
sudo netstat -tulpn
```

Run API tests (battleships-api folder)
```
bin/phpunit

# to get coverage run the commands and access http://10.10.10.10:8080/coverage
sudo mkdir /var/www/html/coverage
sudo chown $(whoami):$(whoami) /var/www/html/coverage
# error about too many files open otherwise
ulimit -n 2048
# error when trying to simply use xdebug
phpdbg -qrr bin/phpunit --coverage-html /var/www/html/coverage/
```

Test API (battleships-apiclient folder)
```
# access web server directly
bin/console test:e2e -v "battleships-api.vagrant:8080/app_dev.php/v1"
# access through Vagrant
bin/console test:e2e "battleships-api.vagrant/v1"
# test Varnish
bin/console test:varnish -vv "battleships-api.vagrant/v1"
```

Varnish commands
```
# see varnish hits
sudo varnishncsa -F '%U%q (%m) %{Varnish:hitmiss}x' -n $(hostname)
# ban/clear cache
sudo varnishadm "ban req.url ~ /"
```

DB commands
```
# check master db status
SHOW MASTER STATUS \G
# check slave db status
SHOW SLAVE STATUS \G
```
