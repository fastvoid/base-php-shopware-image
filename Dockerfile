
FROM php:7.3-fpm-alpine

ARG APP_ENV=prod
ARG TIMEZONE="UTC"
ARG USER_NAME="www-data"
ARG PHP_EXT="bcmath pdo pdo_mysql opcache gd intl json zip pcntl phar sodium simplexml"

WORKDIR /var/www/app

RUN apk update \
    && apk upgrade \
    && apk add --no-cache \
        freetype-dev \
        libpng-dev \
        jpeg-dev \
        libjpeg-turbo-dev

RUN docker-php-ext-configure gd \
        --with-freetype-dir=/usr/lib/ \
        --with-png-dir=/usr/lib/ \
        --with-jpeg-dir=/usr/lib/ \
        --with-gd

COPY build.sh /build.sh
RUN sh /build.sh

RUN docker-php-ext-install $PHP_EXT && docker-php-ext-enable opcache

RUN apk add --no-cache rabbitmq-c-dev && \
    mkdir -p /usr/src/php/ext/amqp && \
    curl -fsSL https://pecl.php.net/get/amqp | tar xvz -C "/usr/src/php/ext/amqp" --strip 1 && \
    docker-php-ext-install amqp

COPY --from=composer /usr/bin/composer /usr/bin/composer