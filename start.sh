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
fi

# Show the generated .env for debugging
echo "=== Generated .env ==="
cat /var/www/html/.env
echo "====================="

# Clear Laravel cache
cd /var/www/html
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# Test database connection
php artisan tinker --execute="DB::connection()->getPdo(); echo 'Database connected!';" 2>&1 || echo "Database connection failed!"

# Start PHP server
exec php -S 0.0.0.0:${PORT:-8080} -t /var/www/html
