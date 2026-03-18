#!/bin/bash

# Replace Railway variables
if [ -f /var/www/html/.env.railway ]; then
    cp /var/www/html/.env.railway /var/www/html/.env
    sed -i "s|\${MYSQLHOST}|${MYSQLHOST:-localhost}|g" /var/www/html/.env
    sed -i "s|\${MYSQLPORT}|${MYSQLPORT:-3306}|g" /var/www/html/.env
    sed -i "s|\${MYSQLDATABASE}|${MYSQLDATABASE:-railway}|g" /var/www/html/.env
    sed -i "s|\${MYSQLUSER}|${MYSQLUSER:-root}|g" /var/www/html/.env
    sed -i "s|\${MYSQLPASSWORD}|${MYSQLPASSWORD}|g" /var/www/html/.env
    sed -i "s|\${RAILWAY_STATIC_URL}|${RAILWAY_STATIC_URL}|g" /var/www/html/.env
    sed -i "s|APP_URL=.*|APP_URL=https://${RAILWAY_STATIC_URL:-}|g" /var/www/html/.env
fi

# Clear Laravel cache
cd /var/www/html
php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true

echo "Starting PHP-FPM and Nginx on port 8080..."
php-fpm &
nginx -g "daemon off;"
