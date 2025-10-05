FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json ./
RUN composer install --no-dev --prefer-dist --no-interaction --ignore-platform-reqs

FROM php:8.2-fpm-alpine

RUN apk add --no-cache \
    bash git curl zip unzip \
    libpng-dev libjpeg-turbo-dev libwebp-dev libzip-dev oniguruma-dev \
    postgresql-dev icu-dev icu-libs libxml2-dev \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install \
        pdo pdo_pgsql mbstring exif pcntl bcmath gd zip intl \
    && rm -rf /var/cache/apk/*

WORKDIR /var/www/html
COPY . .

COPY --from=vendor /app/vendor ./vendor

RUN chmod -R 775 storage bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]
