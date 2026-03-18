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
fi

# Enable PHP error display
echo "display_errors=On" >> /usr/local/etc/php/conf.d/error_display.ini
echo "error_reporting=E_ALL" >> /usr/local/etc/php/conf.d/error_display.ini

# Clear Laravel cache
cd /var/www/html
php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true

# Create admin user if not exists
php artisan tinker --execute="
try {
    \$user = App\Models\User::where('email', 'admin@admin.com')->first();
    if (!\$user) {
        App\Models\User::create([
            'name' => 'Admin',
            'email' => 'admin@admin.com',
            'password' => Hash::make('123456'),
            'email_verified_at' => now(),
            'user_type' => 'admin'
        ]);
        echo 'Admin user created!';
    } else {
        echo 'Admin user already exists';
    }
} catch (Exception \$e) {
    echo 'Error: ' . \$e->getMessage();
}
" 2>/dev/null || true

echo "Starting PHP-FPM and Nginx on port 8080..."
php-fpm &
nginx -g "daemon off;"
