#!/bin/bash

battleshipsVarDir=$1

cd /var/www/battleships-api
# Set folder permissions (http://symfony.com/doc/current/book/installation.html)
if [ $battleshipsVarDir ]; then
    varDir="$battleshipsVarDir/var"
else
    varDir=var
fi

# create folder doesn't exist
if [ ! -d $varDir ]; then
    mkdir $varDir
fi

HTTPDUSER=`ps axo user,comm | grep -E '[a]pache|[h]ttpd|[_]www|[w]ww-data|[n]ginx' | grep -v root | head -1 | cut -d\  -f1`
sudo setfacl -R -m u:"$HTTPDUSER":rwX -m u:`whoami`:rwX $varDir
sudo setfacl -dR -m u:"$HTTPDUSER":rwX -m u:`whoami`:rwX $varDir
