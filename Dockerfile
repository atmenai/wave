# ============================
# 🧱 Stage 1: Build Composer deps
# ============================
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer update --no-dev --prefer-dist --no-interaction --ignore-platform-reqs --no-scripts && \
    composer install --no-dev --prefer-dist --no-interaction --ignore-platform-reqs --no-scripts

# ============================
# 🚀 Stage 2: App (PHP + Nginx)
# ============================
FROM php:8.2-fpm

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

WORKDIR /var/www/html

COPY . .
COPY --from=vendor /app/vendor ./vendor

RUN mkdir -p storage/framework/{cache,sessions,views} \
    storage/logs \
    bootstrap/cache

RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache && \
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

RUN php artisan package:discover --ansi || true && \
    php artisan config:cache || true && \
    php artisan route:cache || true && \
    php artisan view:cache || true

COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN rm -f /etc/nginx/sites-enabled/default || true

EXPOSE 80
EXPOSE 443

RUN mkdir -p /etc/ssl/private /etc/ssl/certs && \
    openssl req -x509 -nodes -days 365 \
    -subj "/C=SA/ST=Makkah/L=Jeddah/O=AtmenAI/CN=atmenai.com" \
    -addext "subjectAltName=DNS:atmenai.com" \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt

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

CMD ["sh", "-c", "service nginx start && php-fpm"]
