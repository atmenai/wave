# ============================
# 🧱 Stage 1: Build Composer deps
# ============================
FROM composer:2 AS vendor

WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --ignore-platform-reqs

# ============================
# 🚀 Stage 2: App (PHP + Nginx)
# ============================
FROM php:8.2-fpm

# Install required libraries and extensions
RUN apt-get update && apt-get install -y \
    nginx git curl zip unzip libpng-dev libjpeg-dev libwebp-dev libzip-dev zlib1g-dev libpq-dev libicu-dev g++ \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install gd zip exif pdo pdo_pgsql intl mbstring bcmath opcache \
    && rm -rf /var/lib/apt/lists/*

# Copy application code
WORKDIR /var/www/html
COPY . .

# Copy Composer dependencies from build stage
COPY --from=vendor /app/vendor ./vendor

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose web port
EXPOSE 80

# Start Nginx and PHP-FPM together
CMD service nginx start && php-fpm
