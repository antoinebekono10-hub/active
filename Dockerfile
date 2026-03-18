FROM php:8.2-fpm

# Install system dependencies and nginx
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    default-mysql-client \
    nginx \
    && docker-php-ext-configure gd \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install mbstring exif pcntl bcmath zip mysqli pdo pdo_mysql

# Configure Nginx
RUN echo 'server { \
    listen $PORT; \
    server_name _; \
    root /var/www/html; \
    index index.php index.html; \
    \
    client_max_body_size 100M; \
    \
    location / { \
        try_files $uri $uri/ /index.php?$query_string; \
    } \
    \
    location ~ \.php$ { \
        try_files $uri =404; \
        fastcgi_split_path_info ^(.+\.php)(/.+)$; \
        fastcgi_pass 127.0.0.1:9000; \
        fastcgi_index index.php; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
        fastcgi_param PATH_INFO $fastcgi_path_info; \
    } \
    \
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ { \
        expires max; \
        log_not_found off; \
    } \
}' > /etc/nginx/sites-available/default

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html

# Create startup script
RUN echo '#!/bin/bash \
# Replace Railway variables \
if [ -f /var/www/html/.env.railway ]; then \
    cp /var/www/html/.env.railway /var/www/html/.env \
    sed -i "s|\${MYSQLHOST}|${MYSQLHOST:-localhost}|g" /var/www/html/.env \
    sed -i "s|\${MYSQLPORT}|${MYSQLPORT:-3306}|g" /var/www/html/.env \
    sed -i "s|\${MYSQLDATABASE}|${MYSQLDATABASE:-railway}|g" /var/www/html/.env \
    sed -i "s|\${MYSQLUSER}|${MYSQLUSER:-root}|g" /var/www/html/.env \
    sed -i "s|\${MYSQLPASSWORD}|${MYSQLPASSWORD}|g" /var/www/html/.env \
    sed -i "s|\${RAILWAY_STATIC_URL}|${RAILWAY_STATIC_URL}|g" /var/www/html/.env \
    sed -i "s|APP_URL=.*|APP_URL=https://${RAILWAY_STATIC_URL:-}|g" /var/www/html/.env \
fi \
echo "Starting PHP-FPM and Nginx..." \
php-fpm & \
nginx -g "daemon off;" \
' > /start.sh && chmod +x /start.sh

# Set permissions
RUN chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 777 /var/www/html/
RUN chmod 666 /var/www/html/.env 2>/dev/null || true

# Expose port
EXPOSE 80 8080 3000

# Run startup script
CMD ["/start.sh"]
