# ---------------------------
# مرحلة 1: تثبيت الاعتمادات (Composer)
# ---------------------------
FROM composer:2 AS vendor

WORKDIR /app
COPY composer.json ./
RUN composer install --no-dev --prefer-dist --no-interaction --ignore-platform-reqs

# ---------------------------
# مرحلة 2: بيئة التشغيل PHP-FPM + Nginx
# ---------------------------
FROM php:8.2-fpm-alpine

# تثبيت الحزم المطلوبة
RUN apk add --no-cache bash git curl nginx zip unzip \
    libpng-dev libjpeg-turbo-dev libwebp-dev libzip-dev oniguruma-dev \
    postgresql-dev icu-dev icu-libs libxml2-dev \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install pdo pdo_pgsql mbstring exif pcntl bcmath gd zip intl \
    && rm -rf /var/cache/apk/*

# إنشاء مجلد العمل
WORKDIR /var/www/html

# نسخ ملفات المشروع
COPY . .

# نسخ مكتبات vendor من المرحلة الأولى
COPY --from=vendor /app/vendor ./vendor

# إعداد صلاحيات التخزين والتخزين المؤقت
RUN chmod -R 775 storage bootstrap/cache

# نسخ إعدادات nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# فتح المنافذ
EXPOSE 80

# تشغيل الخدمات (nginx + php-fpm)
CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]
