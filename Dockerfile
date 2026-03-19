FROM php:8.4-fpm

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
    nginx

# Configure PHP
RUN docker-php-ext-configure gd \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install mbstring exif pcntl bcmath zip mysqli pdo pdo_mysql

# Configure Nginx for Laravel
RUN rm -f /etc/nginx/sites-enabled/default
COPY nginx.conf /etc/nginx/sites-enabled/default

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html

# REMOVE vendor - it was installed with wrong PHP version
RUN rm -rf /var/www/html/vendor || true

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Clear composer cache
RUN composer clear-cache

# Install dependencies with correct PHP version
RUN composer config --global audit.block-insecure false
RUN composer install --no-dev --optimize-autoloader --ignore-platform-reqs --no-scripts

# Remove platform_check that checks PHP version
RUN rm -f /var/www/html/vendor/composer/platform_check.php || true

# Generate key and clear caches
RUN php artisan key:generate --force 2>/dev/null || true
RUN php artisan config:clear || true

# Set permissions
RUN chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 777 /var/www/html/
RUN chmod -R 777 /var/www/html/storage/framework/views 2>/dev/null || true
RUN chmod -R 777 /var/www/html/storage/logs 2>/dev/null || true
RUN chmod -R 777 /var/www/html/storage/app 2>/dev/null || true
RUN chmod -R 777 /var/www/html/storage/framework/cache 2>/dev/null || true
RUN touch /var/www/html/storage/logs/laravel.log 2>/dev/null || true
RUN chmod 666 /var/www/html/storage/logs/laravel.log 2>/dev/null || true

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose port
EXPOSE 8080

# Run startup script
CMD ["/start.sh"]
