#!/bin/bash
set -e

echo "=== Starting MERCA Application ==="

# Replace Railway variables in .env
if [ -f /var/www/html/.env.railway ]; then
    echo "Generating .env from template..."
    cp /var/www/html/.env.railway /var/www/html/.env
    
    # Replace MySQL variables
    sed -i "s|\${MYSQLHOST}|${MYSQLHOST:-localhost}|g" /var/www/html/.env
    sed -i "s|\${MYSQLPORT}|${MYSQLPORT:-3306}|g" /var/www/html/.env
    sed -i "s|\${MYSQLDATABASE}|${MYSQLDATABASE:-railway}|g" /var/www/html/.env
    sed -i "s|\${MYSQLUSER}|${MYSQLUSER:-root}|g" /var/www/html/.env
    sed -i "s|\${MYSQLPASSWORD}|${MYSQLPASSWORD}|g" /var/www/html/.env
    
    # Replace Redis variables
    sed -i "s|\${REDISHOST}|${REDISHOST:-127.0.0.1}|g" /var/www/html/.env
    sed -i "s|\${REDISPASSWORD}|${REDISPASSWORD}|g" /var/www/html/.env
    sed -i "s|\${REDISPORT}|${REDISPORT:-6379}|g" /var/www/html/.env
    
    # Replace Railway URL
    sed -i "s|\${RAILWAY_STATIC_URL}|${RAILWAY_STATIC_URL}|g" /var/www/html/.env
    
    # Set APP_URL for Railway
    sed -i "s|APP_URL=.*|APP_URL=https://${RAILWAY_STATIC_URL}|g" /var/www/html/.env
    sed -i "s|ASSET_URL=.*|ASSET_URL=|g" /var/www/html/.env
    
    # Ensure HTTPS is off for HTTP connections
    sed -i "s|FORCE_HTTPS=.*|FORCE_HTTPS=Off|g" /var/www/html/.env
fi

# Ensure .env exists
if [ ! -f /var/www/html/.env ]; then
    echo "WARNING: .env not found, creating from .env.example..."
    cp /var/www/html/.env.example /var/www/html/.env 2>/dev/null || true
fi

# Clear Laravel caches
cd /var/www/html
echo "Clearing Laravel caches..."
php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

# Check and import database if empty
echo "Checking database..."
TABLE_COUNT=$(mysql --ssl-verify-server-cert=0 -h ${MYSQLHOST:-localhost} -P ${MYSQLPORT:-3306} -u ${MYSQLUSER:-root} -p${MYSQLPASSWORD:-} ${MYSQLDATABASE:-railway} -e "SHOW TABLES" 2>/dev/null | tail -n +2 | wc -l || echo "0")
echo "Database has $TABLE_COUNT tables"

if [ "$TABLE_COUNT" -eq 0 ]; then
    echo "Database is empty, importing shop.sql..."
    mysql --ssl-verify-server-cert=0 -h ${MYSQLHOST:-localhost} -P ${MYSQLPORT:-3306} -u ${MYSQLUSER:-root} -p${MYSQLPASSWORD:-} ${MYSQLDATABASE:-railway} < /var/www/html/shop.sql 2>/dev/null && echo "Import complete!" || echo "Import failed!"
else
    echo "Database already has data, skipping import."
fi

# Show .env for debugging
echo "=== Current .env (APP_URL) ==="
grep APP_URL /var/www/html/.env || echo "APP_URL not found"

echo "=== Starting PHP-FPM and Nginx ==="
echo "PHP-FPM and Nginx started on port 8080"

# Start services
php-fpm &
nginx -g "daemon off;"
