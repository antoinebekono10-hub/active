#!/bin/bash

# Replace Railway variables in .env.railway
if [ -f /var/www/html/.env.railway ]; then
    cp /var/www/html/.env.railway /var/www/html/.env
    
    # Use PHP to properly handle variable substitution
    php -r "
        \$env = file_get_contents('/var/www/html/.env');
        \$env = str_replace('\${MYSQLHOST}', getenv('MYSQLHOST') ?: 'localhost', \$env);
        \$env = str_replace('\${MYSQLPORT}', getenv('MYSQLPORT') ?: '3306', \$env);
        \$env = str_replace('\${MYSQLDATABASE}', getenv('MYSQLDATABASE') ?: 'railway', \$env);
        \$env = str_replace('\${MYSQLUSER}', getenv('MYSQLUSER') ?: 'root', \$env);
        \$env = str_replace('\${MYSQLPASSWORD}', getenv('MYSQLPASSWORD') ?: '', \$env);
        \$env = str_replace('\${REDISHOST}', getenv('REDISHOST') ?: '127.0.0.1', \$env);
        \$env = str_replace('\${REDISPASSWORD}', getenv('REDISPASSWORD') ?: '', \$env);
        \$env = str_replace('\${REDISPORT}', getenv('REDISPORT') ?: '6379', \$env);
        \$env = str_replace('\${RAILWAY_STATIC_URL}', getenv('RAILWAY_STATIC_URL') ?: '', \$env);
        file_put_contents('/var/www/html/.env', \$env);
    "
    
    # Also fix APP_URL directly in .env file
    sed -i "s|APP_URL=.*|APP_URL=https://${RAILWAY_STATIC_URL:-}|g" /var/www/html/.env
    sed -i "s|ASSET_URL=.*|ASSET_URL=|g" /var/www/html/.env
fi

# Enable PHP error display
echo "display_errors=On" >> /usr/local/etc/php/conf.d/error_display.ini
echo "error_reporting=E_ALL" >> /usr/local/etc/php/conf.d/error_display.ini
echo "log_errors=On" >> /usr/local/etc/php/conf.d/error_display.ini
echo "error_log=/tmp/php_errors.log" >> /usr/local/etc/php/conf.d/error_display.ini

# Clear ALL Laravel caches
cd /var/www/html
php artisan config:clear 2>&1 || true
php artisan cache:clear 2>&1 || true
php artisan route:clear 2>&1 || true
php artisan view:clear 2>&1 || true

# Test database connection
echo "Testing database connection..."
php -r "
try {
    \$pdo = new PDO('mysql:host=${MYSQLHOST:-localhost};port=${MYSQLPORT:-3306};dbname=${MYSQLDATABASE:-railway}', '${MYSQLUSER:-root}', '${MYSQLPASSWORD:-}');
    echo 'Database connected successfully!';
} catch (PDOException \$e) {
    echo 'Database connection failed: ' . \$e->getMessage();
}
" 2>&1

# Test Laravel route
echo "Testing Laravel route..."
php /var/www/html/artisan route:list 2>&1 | head -20

# Show .env content for debugging
echo "=== .env content ==="
cat /var/www/html/.env
echo "==================="

# Start PHP server with full error output
exec php -S 0.0.0.0:${PORT:-8080} -t /var/www/html /var/www/html/server.php 2>&1
