###############################
# Dockerfile for Atmen AI (Laravel / Wave)
# PHP 8.2 + Composer + PostgreSQL + Coolify
###############################

# ---------- مرحلة البناء (Composer) ----------
FROM composer:2 AS vendor

WORKDIR /app

# انسخ كل ملفات المشروع وليس فقط composer.json
COPY . .

# ثبّت الاعتمادات
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader --ignore-platform-reqs


# ---------- مرحلة التشغيل (PHP-FPM) ----------
FROM php:8.2-fpm-alpine

# تثبيت الحزم المطلوبة
RUN apk add --no-cache \
    bash git curl zip unzip \
    libpng-dev libjpeg-turbo-dev libwebp-dev libzip-dev oniguruma-dev \
    postgresql-dev icu-dev icu-libs libxml2-dev \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install \
        pdo pdo_pgsql mbstring exif pcntl bcmath gd zip intl \
    && rm -rf /var/cache/apk/*

WORKDIR /var/www/html

# نسخ الملفات من مرحلة البناء
COPY --from=vendor /app ./

# أذونات التخزين والـ cache
RUN chmod -R 775 storage bootstrap/cache

EXPOSE 9000

CMD ["php-fpm"]
