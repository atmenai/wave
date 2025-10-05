##############################################
# 🧠 Dockerfile for Atmen AI (Laravel / Wave)
# PHP 8.2 + Composer + PostgreSQL + Coolify
##############################################

# ---------- مرحلة البناء (Composer) ----------
FROM composer:2 AS vendor

WORKDIR /app

# تثبيت الامتدادات المطلوبة أثناء البناء
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libwebp-dev libzip-dev libicu-dev unzip git \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install gd exif intl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# نسخ ملفات Laravel
COPY composer.json ./

# تثبيت الاعتمادات بدون ملف composer.lock
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

# ---------- مرحلة التشغيل (PHP-FPM) ----------
FROM php:8.2-fpm-alpine

# تثبيت المكتبات المطلوبة للنظام
RUN apk add --no-cache bash git curl zip unzip libpng-dev libjpeg-turbo-dev libwebp-dev libzip-dev oniguruma-dev postgresql-dev icu-dev \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install pdo pdo_pgsql mbstring exif pcntl bcmath gd zip intl

WORKDIR /var/www/html

# نسخ ملفات المشروع (wave/)
COPY . .

# نسخ vendor من مرحلة البناء
COPY --from=vendor /app/vendor ./vendor

# إعداد التخزين (اختياري)
RUN php artisan storage:link || true

EXPOSE 9000

CMD ["php-fpm"]
