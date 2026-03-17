FROM php:8.2-cli

# Install system dependencies
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
    && docker-php-ext-configure gd \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install mbstring exif pcntl bcmath zip mysqli pdo

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html

# Create .env file from .env.railway template (or .env.example as fallback)
RUN if [ -f /var/www/html/.env.railway ]; then \
        cp /var/www/html/.env.railway /var/www/html/.env; \
    elif [ -f /var/www/html/.env.example ]; then \
        cp /var/www/html/.env.example /var/www/html/.env; \
    fi

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Generate application key and install dependencies
RUN php /var/www/html/artisan key:generate || true
RUN composer config --global audit.block-insecure false
RUN composer install --no-dev --optimize-autoloader --ignore-platform-reqs --no-scripts

# Run artisan commands
RUN php /var/www/html/artisan package:discover --ansi || true
RUN php /var/www/html/artisan config:clear || true
RUN php /var/www/html/artisan cache:clear || true
RUN php /var/www/html/artisan view:clear || true
RUN php /var/www/html/artisan route:clear || true

# Set permissions - must be writable for installer
RUN chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 777 /var/www/html/
RUN chmod 666 /var/www/html/.env 2>/dev/null || true
RUN chmod 666 /var/www/html/app/Providers/RouteServiceProvider.php 2>/dev/null || true
RUN chmod -R 777 /var/www/html/storage/framework/ /var/www/html/bootstrap/cache/

# Create storage link
RUN php /var/www/html/artisan storage:link 2>/dev/null || true

# Set permissions
RUN chmod +x /var/www/html/start.sh

# Expose port
EXPOSE 8080

# Start PHP built-in server
CMD ["/var/www/html/start.sh"]
