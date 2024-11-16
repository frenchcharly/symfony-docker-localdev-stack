# Build the PHP container
FROM php:8.2-fpm

# Install dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev \
    && docker-php-ext-install -j$(nproc) pdo pdo_mysql pdo_pgsql pgsql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set working directory
WORKDIR /app

# Copy application files
COPY ./webapp .

# Set timezone
ENV TZ=Europe/Paris
