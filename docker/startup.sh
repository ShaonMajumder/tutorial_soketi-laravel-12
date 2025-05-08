#!/bin/bash

cd /var/www/html

# If artisan not found, assume Laravel not present
if [ ! -f artisan ]; then
    echo "Laravel not found. Creating Laravel in /tmp/laravel..."
    composer create-project --prefer-dist laravel/laravel /tmp/laravel

    echo "Copying Laravel to current directory..."
    cp -R /tmp/laravel/. .
    rm -rf /tmp/laravel
else
    echo "Laravel already exists. Skipping creation."
fi

exec "$@"
