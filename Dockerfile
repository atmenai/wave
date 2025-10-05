# ============================
# 🧱 Stage 1: Build Composer deps
# ============================
FROM composer:2 AS vendor

WORKDIR /app

# نسخ composer.json فقط أولاً
COPY composer.json ./

# تحديث وتثبيت المكتبات (سيُنشئ composer.lock تلقائياً)
RUN composer update --no-dev --prefer-dist --no-interaction --ignore-platform-reqs && \
    composer install --no-dev --prefer-dist --no-interaction --ignore-platform-reqs

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

# إنشاء المجلدات المطلوبة إذا لم تكن موجودة
RUN mkdir -p storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache

# ضبط الصلاحيات
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache && \
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# نسخ إعدادات Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# حذف الإعداد الافتراضي لـ Nginx
RUN rm -f /etc/nginx/sites-enabled/default

# فتح المنفذ
EXPOSE 80

# تشغيل Nginx و PHP-FPM
CMD ["sh", "-c", "service nginx start && php-fpm"]
