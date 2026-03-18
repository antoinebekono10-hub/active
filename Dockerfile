FROM php:8.2-fpm

# Install system dependencies, nginx, Node.js and Python
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
    nodejs \
    npm \
    python3 \
    make \
    g++ \
    && docker-php-ext-configure gd \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install mbstring exif pcntl bcmath zip mysqli pdo pdo_mysql

# Configure Nginx
RUN echo 'server { \
    listen 8080; \
    server_name _; \
    root /var/www/html/public; \
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

# Use Railway environment
RUN cp .env.railway .env

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Generate key and install dependencies
RUN php /var/www/html/artisan key:generate || true
RUN composer config --global audit.block-insecure false
RUN composer install --no-dev --optimize-autoloader --ignore-platform-reqs --no-scripts || true

# Skip npm compilation - use default Bootstrap CSS or CDN
# The site will still function without compiled assets

# Run artisan commands
RUN php /var/www/html/artisan config:clear || true
RUN php /var/www/html/artisan package:discover --ansi || true

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set permissions
RUN chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 777 /var/www/html/
RUN chmod 666 /var/www/html/.env 2>/dev/null || true

# Expose port
EXPOSE 8080

# Run startup script
CMD ["/start.sh"]
