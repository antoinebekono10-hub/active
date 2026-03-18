#!/bin/bash

echo "===== STARTUP SCRIPT EXECUTION BEGIN ====="

# Replace Railway variables
if [ -f /var/www/html/.env.railway ]; then
    echo "INFO: Found .env.railway file"
    cp /var/www/html/.env.railway /var/www/html/.env
    echo "INFO: Copied .env.railway to .env"
    
    # Debug: Show environment variables received from Railway
    echo "===== RAILWAY ENVIRONMENT VARIABLES ====="
    echo "MYSQLHOST: '${MYSQLHOST}'"
    echo "MYSQLPORT: '${MYSQLPORT}'"
    echo "MYSQLDATABASE: '${MYSQLDATABASE}'"
    echo "MYSQLUSER: '${MYSQLUSER}'"
    # Don't print password for security, but check if it's set
    if [ -z "${MYSQLPASSWORD}" ]; then
        echo "MYSQLPASSWORD: '[EMPTY]'"
    else
        echo "MYSQLPASSWORD: '[SET]'"
    fi
    echo "RAILWAY_STATIC_URL: '${RAILWAY_STATIC_URL}'"
    echo "===== END RAILWAY ENVIRONMENT VARIABLES ====="
    
    # Check if any critical variables are empty
    MISSING_VARS=()
    [ -z "${MYSQLHOST}" ] && MISSING_VARS+=("MYSQLHOST")
    [ -z "${MYSQLPORT}" ] && MISSING_VARS+=("MYSQLPORT")
    [ -z "${MYSQLDATABASE}" ] && MISSING_VARS+=("MYSQLDATABASE")
    [ -z "${MYSQLUSER}" ] && MISSING_VARS+=("MYSQLUSER")
    [ -z "${MYSQLPASSWORD}" ] && MISSING_VARS+=("MYSQLPASSWORD")
    [ -z "${RAILWAY_STATIC_URL}" ] && MISSING_VARS+=("RAILWAY_STATIC_URL")
    
    if [ ${#MISSING_VARS[@]} -gt 0 ]; then
        echo "ERROR: Missing or empty variables: ${MISSING_VARS[*]}"
    else
        echo "INFO: All critical variables appear to be set"
    fi
    
    echo "===== PERFORMING VARIABLE SUBSTITUTION ====="
    # Show what we're about to substitute
    echo "Before substitution - checking for placeholders in .env:"
    grep -n "\${MYSQLHOST}\|\${MYSQLPORT}\|\${MYSQLDATABASE}\|\${MYSQLUSER}\|\${MYSQLPASSWORD}\|\${RAILWAY_STATIC_URL}" /var/www/html/.env || echo "No placeholders found (already substituted or not present)"
    
    # Perform substitutions with error checking
    echo "Substituting MYSQLHOST..."
    sed -i "s|\${MYSQLHOST}|${MYSQLHOST:-placeholder_not_set}|g" /var/www/html/.env
    
    echo "Substituting MYSQLPORT..."
    sed -i "s|\${MYSQLPORT}|${MYSQLPORT:-placeholder_not_set}|g" /var/www/html/.env
    
    echo "Substituting MYSQLDATABASE..."
    sed -i "s|\${MYSQLDATABASE}|${MYSQLDATABASE:-placeholder_not_set}|g" /var/www/html/.env
    
    echo "Substituting MYSQLUSER..."
    sed -i "s|\${MYSQLUSER}|${MYSQLUSER:-placeholder_not_set}|g" /var/www/html/.env
    
    echo "Substituting MYSQLPASSWORD..."
    sed -i "s|\${MYSQLPASSWORD}|${MYSQLPASSWORD:-placeholder_not_set}|g" /var/www/html/.env
    
    echo "Substituting RAILWAY_STATIC_URL..."
    sed -i "s|\${RAILWAY_STATIC_URL}|${RAILWAY_STATIC_URL:-placeholder_not_set}|g" /var/www/html/.env
    
    # Check if any placeholders remain
    echo "After substitution - checking for remaining placeholders:"
    if grep -q "\${MYSQLHOST}\|\${MYSQLPORT}\|\${MYSQLDATABASE}\|\${MYSQLUSER}\|\${MYSQLPASSWORD}\|\${RAILWAY_STATIC_URL}" /var/www/html/.env; then
        echo "ERROR: Some placeholders were not substituted!"
        grep -n "\${MYSQLHOST}\|\${MYSQLPORT}\|\${MYSQLDATABASE}\|\${MYSQLUSER}\|\${MYSQLPASSWORD}\|\${RAILWAY_STATIC_URL}" /var/www/html/.env
    else
        echo "SUCCESS: All placeholders appear to have been substituted"
    fi
    
    # Show a sample of the final .env (masked)
    echo "===== FINAL .ENV SAMPLE (first 5 lines, values masked) ====="
    head -5 /var/www/html/.env | while IFS= read -r line; do
        if [[ $line =~ ^[^=]+= ]]; then
            key="${line%%=*}"
            echo "${key}=[VALUE_MASKED]"
        else
            echo "$line"
        fi
    done
    echo "===== END .ENV SAMPLE ====="
else
    echo "ERROR: .env.railway file not found at /var/www/html/.env.railway"
    echo "Directory contents:"
    ls -la /var/www/html/
fi

# Enable PHP error display
echo "display_errors=On" >> /usr/local/etc/php/conf.d/error_display.ini
echo "error_reporting=E_ALL" >> /usr/local/etc/php/conf.d/error_display.ini

# Clear Laravel cache
echo "===== CLEARING LARAVEL CACHE ====="
cd /var/www/html
php artisan config:clear 2>/dev/null || echo "WARNING: config:clear failed"
php artisan cache:clear 2>/dev/null || echo "WARNING: cache:clear failed"

# Create admin user if not exists
echo "===== CHECKING/CREATING ADMIN USER ====="
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
    echo 'Error during admin user check/creation: ' . \$e->getMessage();
}
" 2>/dev/null || true

echo "===== STARTING SERVICES ====="
echo "Starting PHP-FPM and Nginx on port 8080..."
php-fpm &
nginx -g "daemon off;"

echo "===== STARTUP SCRIPT EXECUTION END ====="