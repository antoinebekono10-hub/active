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
    && docker-php-ext-install mbstring exif pcntl bcmath zip mysqli

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html

# Create .env file if not exists
RUN cp /var/www/html/.env.example /var/www/html/.env || true

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Generate application key and install dependencies
RUN php /var/www/html/artisan key:generate || true
RUN composer config --global audit.block-insecure false
RUN composer install --no-dev --optimize-autoloader --ignore-platform-reqs

# Set permissions - 666 for .env (read/write), 644 for RouteServiceProvider
RUN chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod 666 /var/www/html/.env 2>/dev/null || true
RUN chmod 644 /var/www/html/app/Providers/RouteServiceProvider.php 2>/dev/null || true

# Create storage link
RUN php /var/www/html/artisan storage:link 2>/dev/null || true

# Expose port
EXPOSE 8080

# Start PHP built-in server from root directory
CMD sh -c "php -S 0.0.0.0:${PORT:-8080} -t /var/www/html"
