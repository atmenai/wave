# ============================
# 🧱 Stage 1: Build Composer deps
# ============================
FROM composer:2 AS vendor

WORKDIR /app

# نسخ composer.json فقط
COPY composer.json ./

# تحديث وتثبيت مع تجاهل أوامر post-install
RUN composer update --no-dev --prefer-dist --no-interaction --ignore-platform-reqs --no-scripts && \
    composer install --no-dev --prefer-dist --no-interaction --ignore-platform-reqs --no-scripts

# ============================
# 🚀 Stage 2: App (PHP + Nginx)
# ============================
FROM php:8.2-fpm

# تثبيت المكتبات المطلوبة
RUN apt-get update && apt-get install -y \
    nginx \
    git \
    curl \
    zip \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libzip-dev \
    zlib1g-dev \
    libpq-dev \
    libicu-dev \
    g++ \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install gd zip exif pdo pdo_pgsql intl mbstring bcmath opcache \
    && rm -rf /var/lib/apt/lists/*

# إعداد مجلد العمل
WORKDIR /var/www/html

# نسخ كود التطبيق
COPY . .

# نسخ مكتبات Composer من المرحلة الأولى
COPY --from=vendor /app/vendor ./vendor

# إنشاء المجلدات المطلوبة
RUN mkdir -p storage/framework/{cache,sessions,views} \
    storage/logs \
    bootstrap/cache

# ضبط الصلاحيات
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache && \
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# تشغيل أوامر Laravel بعد نسخ الكود
RUN php artisan package:discover --ansi || true && \
    php artisan config:cache || true && \
    php artisan route:cache || true && \
    php artisan view:cache || true

# نسخ إعدادات Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# حذف الإعداد الافتراضي
RUN rm -f /etc/nginx/sites-enabled/default

# فتح المنفذ
EXPOSE 80

# تشغيل Nginx و PHP-FPM
CMD ["sh", "-c", "service nginx start && php-fpm"]
