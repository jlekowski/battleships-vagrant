# Battleships (Vagrant)

## Battleships (sea battle) game - Vagrant settings
Vagrant setup to run and develop Battleships.

### LINKS
* https://github.com/jlekowski/battleships-api - API
* https://github.com/jlekowski/battleships-webclient - web client for the API
* https://github.com/jlekowski/battleships-cliclient - CLI client for the API
* https://github.com/jlekowski/battleships-apiclient - PHP client for the API

## === Installation ===
1. Install Vagrant (https://www.vagrantup.com)
2. Download and unzip or clone repository.
3. Run
```
# automatically runs web + 2 DBs (master and slave)
vagrant up
# or to set up GIT with your name and email, and with 3 DBs (master and 2 slaves)
VAGRANT_NAME='John Doe' VAGRANT_EMAIL='john@example.org' VAGRANT_DB_COUNT=3 vagrant up
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
* version **1.2**
  * Setup with PHP 7.1 (API 1.5)
* version **1.1**
  * Multiserver setup (Web + DBs with replication)
  * Dev box configuration
  * Handle parameters for GIT and number of DB instances
  * Refactoring (organise provision scripts)
  * Support for API changes (env variables, Symfony 3.3)
* version **1.0**
  * Working version with API (full server config), Web Client, API Client
  * Some improvements around Windows/Linux host machine config and folder sync required

## === Helpful commands ===
Dependencies security check (battleships-api folder)
```
bin/console security:check
```

Clear Symfony cache, OPCache, APC cache, Varnish Cache (battleships-api folder)
```
bin/console cache:clear --no-warmup --env=prod && bin/console cache:warmup --env=prod
sudo service php7.1-fpm reload
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
bin/console test:e2e http://battleships-api.vagrant:8080/app_dev.php -v
# access through Varnish
bin/console test:e2e http://battleships-api.vagrant
# test Varnish
bin/console test:varnish http://battleships-api.vagrant -vv
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
