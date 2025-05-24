#!/bin/bash

cd /var/www/html

# If artisan not found, assume Laravel not present
if [ ! -f artisan ]; then
    echo "Laravel not found. Creating Laravel in /tmp/laravel..."
    composer create-project --prefer-dist laravel/laravel /tmp/laravel

    echo "Copying .env from environment directory..."
    cp environment/.env /tmp/laravel/.env
    php artisan config:clear

    echo "Copying Laravel to current directory..."
    cp -R /tmp/laravel/. .
    rm -rf /tmp/laravel
else
    echo "Laravel already exists. Skipping creation."
fi

echo "Setting correct permissions for the storage directory..."
chown -R www-data:www-data /var/www/html/storage
chmod -R 775 /var/www/html/storage

# if [ -f environment/.env ]; then
#     echo "Copying .env from environment directory..."
#     cp environment/.env .env
#     php artisan config:clear
# else
#     echo "Warning: environment/.env not found, skipping .env copy."
# fi

exec "$@"
