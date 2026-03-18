FROM php:8.2-apache

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
    && docker-php-ext-install mbstring exif pcntl bcmath zip mysqli pdo pdo_mysql

# Enable Apache mod_rewrite and fix MPM
RUN a2enmod rewrite
RUN a2dismod mpm_event mpm_worker || true
RUN a2enmod mpm_prefork || true

# Configure Apache - point to root directory (this project has index.php at root)
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/000-default.conf \
    && echo '    DocumentRoot /var/www/html' >> /etc/apache2/sites-available/000-default.conf \
    && echo '    <Directory /var/www/html>' >> /etc/apache2/sites-available/000-default.conf \
    && echo '        Options -Indexes +FollowSymLinks' >> /etc/apache2/sites-available/000-default.conf \
    && echo '        AllowOverride All' >> /etc/apache2/sites-available/000-default.conf \
    && echo '        Require all granted' >> /etc/apache2/sites-available/000-default.conf \
    && echo '    </Directory>' >> /etc/apache2/sites-available/000-default.conf \
    && echo '</VirtualHost>' >> /etc/apache2/sites-available/000-default.conf

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html

# Create .env file from .env.railway template
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

# Set permissions
RUN chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 777 /var/www/html/
RUN chmod 666 /var/www/html/.env 2>/dev/null || true

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
