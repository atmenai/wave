# Use PHP with FPM and install Nginx
FROM php:8.2-fpm

# Install Nginx
RUN apt-get update && apt-get install -y nginx

# Copy app files
WORKDIR /var/www/html
COPY . .

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start both PHP-FPM and Nginx together
CMD service nginx start && php-fpm
