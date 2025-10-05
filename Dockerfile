##############################################
# 🧠 Dockerfile for Atmen AI (Laravel / Wave)
# PHP 8.2 + Composer + PostgreSQL + Coolify
##############################################

# ---------- مرحلة البناء (Composer) ----------
FROM composer:2 AS vendor

WORKDIR /app

# تثبيت الامتدادات المطلوبة في بيئة Alpine الخاصة بـ Composer
RUN apk add --no-cache bash git curl zip unzip libpng-dev libjpeg-turbo-dev libwebp-dev libzip-dev icu-dev \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install gd exif intl

# نسخ ملفات Laravel
COPY composer.json ./

# تثبيت الاعتمادات بدون composer.lock (تحديث آمن)
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader --ignore-platform-reqs

# ---------- مرحلة التشغيل (PHP-FPM) ----------
FROM php:8.2-fpm-alpine

# تثبيت مكتبات النظام والامتدادات المطلوبة للتطبيق
RUN apk add --no-cache bash git curl zip unzip libpng-dev libjpeg-turbo-dev libwebp-dev libzip-dev oniguruma-dev postgresql-dev icu-dev \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install pdo pdo_pgsql mbstring exif pcntl bcmath gd zip intl

WORKDIR /var/www/html

# نسخ المشروع
COPY . .

# نسخ vendor من مرحلة البناء
COPY --from=vendor /app/vendor ./vendor

# إعداد التخزين (اختياري)
RUN php artisan storage:link || true

EXPOSE 9000

CMD ["php-fpm"]

