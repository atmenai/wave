# صورة جاهزة فيها Nginx + PHP-FPM
FROM webdevops/php-nginx:8.2

# إعدادات أساسية
ENV WEB_DOCUMENT_ROOT=/app/public
WORKDIR /app

# حزم لازمة للبناء
RUN apt-get update && apt-get install -y \
    git unzip curl gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# تثبيت Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# نسخ الملفات
COPY . /app

# تثبيت PHP deps
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

# بناء الواجهات (إن وجدت)
RUN [ -f package.json ] && npm ci && npm run build || true

# صلاحيات وتوليف لارافيل
RUN chown -R application:application /app/storage /app/bootstrap/cache \
 && php artisan storage:link || true

EXPOSE 80
CMD ["supervisord"]
