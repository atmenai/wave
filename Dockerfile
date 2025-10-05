# ============================
# 🧱 Stage 1: Build Composer deps
# ============================
FROM composer:2 AS vendor
WORKDIR /app
# نسخ composer.json فقط
COPY composer.json composer.lock ./
# تثبيت المكتبات بدون dev لتسريع البناء
RUN composer update --no-dev --prefer-dist --no-interaction --ignore-platform-reqs --no-scripts && \
    composer install --no-dev --prefer-dist --no-interaction --ignore-platform-reqs --no-scripts

# ============================
# 🎨 Stage 2: Build Node assets
# ============================
FROM node:20-alpine AS assets
WORKDIR /app
# نسخ package.json و package-lock.json
COPY package*.json ./
# تثبيت npm dependencies
RUN npm ci --only=production
# نسخ الملفات المطلوبة للبناء
COPY . .
# بناء الأصول باستخدام Vite
RUN npm run build

# ============================
# 🚀 Stage 3: App (PHP + Nginx)
# ============================
FROM php:8.2-fpm

# تثبيت المكتبات المطلوبة لتشغيل Laravel
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
    libonig-dev \
    g++ \
    openssl \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install gd zip exif pdo pdo_pgsql intl mbstring bcmath opcache \
    && rm -rf /var/lib/apt/lists/*

# إعداد مجلد العمل
WORKDIR /var/www/html

# نسخ كود التطبيق
COPY . .

# نسخ مكتبات Composer من المرحلة الأولى
COPY --from=vendor /app/vendor ./vendor

# نسخ الأصول المبنية من المرحلة الثانية
COPY --from=assets /app/public/build ./public/build

# إنشاء المجلدات المطلوبة بواسطة Laravel
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

# حذف الإعداد الافتراضي إن وُجد
RUN rm -f /etc/nginx/sites-enabled/default || true

# فتح المنافذ
EXPOSE 80
EXPOSE 443

# إنشاء شهادة SSL ذاتية
RUN mkdir -p /etc/ssl/private /etc/ssl/certs && \
    openssl req -x509 -nodes -days 365 \
    -subj "/C=SA/ST=Makkah/L=Jeddah/O=AtmenAI/CN=atmenai.com" \
    -addext "subjectAltName=DNS:atmenai.com" \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt

# تعديل إعداد Nginx لدعم SSL
RUN echo '\n\
server {\n\
    listen 443 ssl;\n\
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;\n\
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;\n\
    server_name _;\n\
    root /var/www/html/public;\n\
    index index.php index.html;\n\
\n\
    location / {\n\
        try_files $uri $uri/ /index.php?$query_string;\n\
    }\n\
\n\
    location ~ \.php$ {\n\
        include fastcgi_params;\n\
        fastcgi_pass 127.0.0.1:9000;\n\
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\n\
        fastcgi_index index.php;\n\
    }\n\
}\n' >> /etc/nginx/conf.d/default.conf

# تشغيل Nginx و PHP-FPM
CMD ["sh", "-c", "service nginx start && php-fpm"]
