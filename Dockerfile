##############################################
# 🧠 Dockerfile for Atmen AI (Laravel / Wave)
# PHP 8.2 + Composer + PostgreSQL + Coolify
##############################################

# ---------- مرحلة البناء (Composer) ----------
FROM composer:2 AS vendor

WORKDIR /app

# انسخ ملفات Laravel من المجلد الصحيح
COPY wave/composer.json wave/composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

# ---------- مرحلة التطبيق (PHP-FPM) ----------
FROM php:8.2-fpm-alpine

# تثبيت الحزم المطلوبة
RUN apk add --no-cache bash git curl zip unzip libpng-dev libjpeg-turbo-dev libwebp-dev libzip-dev oniguruma-dev postgresql-dev icu-dev \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install pdo pdo_pgsql mbstring exif pcntl bcmath gd zip intl

WORKDIR /var/www/html

# نسخ كل ملفات المشروع (من المجلد الفرعي wave)
COPY wave/ ./

# نسخ vendor من مرحلة البناء
COPY --from=vendor /app/vendor ./vendor

# ربط التخزين (اختياري)
RUN php artisan storage:link || true

EXPOSE 9000

CMD ["php-fpm"]
