#!/bin/bash

# Replace Railway variables in .env.railway
if [ -f /var/www/html/.env.railway ]; then
    cp /var/www/html/.env.railway /var/www/html/.env
    sed -i "s/\${MYSQLHOST}/${MYSQLHOST:-localhost}/g" /var/www/html/.env
    sed -i "s/\${MYSQLPORT}/${MYSQLPORT:-3306}/g" /var/www/html/.env
    sed -i "s/\${MYSQLDATABASE}/${MYSQLDATABASE:-railway}/g" /var/www/html/.env
    sed -i "s/\${MYSQLUSER}/${MYSQLUSER:-root}/g" /var/www/html/.env
    sed -i "s/\${MYSQLPASSWORD}/${MYSQLPASSWORD:-}/g" /var/www/html/.env
    sed -i "s/\${REDISHOST}/${REDISHOST:-127.0.0.1}/g" /var/www/html/.env
    sed -i "s/\${REDISPASSWORD}/${REDISPASSWORD:-}/g" /var/www/html/.env
    sed -i "s/\${REDISPORT}/${REDISPORT:-6379}/g" /var/www/html/.env
    sed -i "s/\${RAILWAY_STATIC_URL}/${RAILWAY_STATIC_URL:-}/g" /var/www/html/.env
fi

# Start PHP server
exec php -S 0.0.0.0:${PORT:-8080} -t /var/www/html
