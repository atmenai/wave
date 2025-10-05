# ---------- مرحلة بناء الاعتمادات ----------
FROM composer:2 AS vendor
WORKDIR /app

# انسخ ملفات composer فقط لتثبيت الاعتمادات
COPY composer.json ./
RUN composer install --no-dev --prefer-dist --no-interaction --ignore-platform-reqs

# ---------- مرحلة التطبيق (PHP-FPM) ----------
FROM php:8.2-fpm-alpine

# تثبيت المتطلبات الأساسية وامتدادات PHP
RUN apk add --no-cache \
    bash git curl zip unzip \
    libpng-dev libjpeg-turbo-dev libwebp-dev libzip-dev oniguruma-dev \
    postgresql-dev icu-dev icu-libs libxml2-dev \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install \
        pdo pdo_pgsql mbstring exif pcntl bcmath gd zip intl \
    && rm -rf /var/cache/apk/*

# نسخ ملفات المشروع من مجلد wave
WORKDIR /var/www/html
COPY wave/ .

# نسخ الاعتمادات المثبتة من مرحلة vendor
COPY --from=vendor /app/vendor ./vendor

# ضبط الصلاحيات
RUN chmod -R 775 storage bootstrap/cache

# إعداد نقطة الدخول
EXPOSE 9000
CMD ["php-fpm"]
