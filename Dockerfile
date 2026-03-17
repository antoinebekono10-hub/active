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

# Expose port
EXPOSE 8080

# Start PHP built-in server - regenerate .env at runtime with Railway variables
CMD sh -c "php -r \"
\$envContent = file_get_contents('/var/www/html/.env.railway');
\$envContent = str_replace('\${MYSQLHOST}', getenv('MYSQLHOST') ?: 'localhost', \$envContent);
\$envContent = str_replace('\${MYSQLPORT}', getenv('MYSQLPORT') ?: '3306', \$envContent);
\$envContent = str_replace('\${MYSQLDATABASE}', getenv('MYSQLDATABASE') ?: 'railway', \$envContent);
\$envContent = str_replace('\${MYSQLUSER}', getenv('MYSQLUSER') ?: 'root', \$envContent);
\$envContent = str_replace('\${MYSQLPASSWORD}', getenv('MYSQLPASSWORD') ?: '', \$envContent);
\$envContent = str_replace('\${REDISHOST}', getenv('REDISHOST') ?: '127.0.0.1', \$envContent);
\$envContent = str_replace('\${REDISPASSWORD}', getenv('REDISPASSWORD') ?: '', \$envContent);
\$envContent = str_replace('\${REDISPORT}', getenv('REDISPORT') ?: '6379', \$envContent);
\$envContent = str_replace('\${RAILWAY_STATIC_URL}', getenv('RAILWAY_STATIC_URL') ?: '', \$envContent);
file_put_contents('/var/www/html/.env', \$envContent);
\" && php -S 0.0.0.0:${PORT:-8080} -t /var/www/html"
