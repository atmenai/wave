# ---------- مرحلة البناء ----------
FROM composer:2 AS vendor

WORKDIR /app

# انسخ ملفات Laravel فقط
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

# ---------- مرحلة التطبيق ----------
FROM php:8.2-fpm-alpine

# تثبيت الحزم اللازمة
RUN apk add --no-cache bash git curl zip unzip libpng-dev libjpeg-turbo-dev libwebp-dev libzip-dev oniguruma-dev postgresql-dev icu-dev \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install pdo pdo_pgsql mbstring exif pcntl bcmath gd zip intl

WORKDIR /var/www/html

# نسخ ملفات المشروع
COPY . .

# نسخ vendor من مرحلة البناء
COPY --from=vendor /app/vendor ./vendor

# إعدادات Laravel
RUN php artisan storage:link || true

EXPOSE 9000

CMD ["php-fpm"]

