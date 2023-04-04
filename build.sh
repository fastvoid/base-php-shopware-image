#!/usr/bin/env bash

TIMEZONE="UTC"

set -e
set -x

apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS
apk add --no-cache --update libzip-dev libpng-dev libjpeg-turbo libxml2-dev icu-dev bash libsodium-dev libressl-dev supervisor
pecl install -o -f redis iconv
echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini
rm -rf /usr/share/php
rm -rf /tmp/*
apk del .phpize-deps $PHPIZE_DEPS
apk add --update nodejs npm

apk add --no-cache tzdata oniguruma-dev
cp /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo "$TIMEZONE" >  /etc/timezone && apk del tzdata
apk del tzdata

# Downgrade nodejs for the admin-js and JS build.
apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/v3.12/main/ nodejs=12.22.12-r0 npm

# this might be increased for larger size project
# https://www.scalingphpbook.com/blog/2014/02/14/best-zend-opcache-settings.html
# https://tideways.com/profiler/blog/fine-tune-your-opcache-configuration-to-avoid-caching-suprises
{
    echo 'opcache.memory_consumption=128'
    echo 'opcache.interned_strings_buffer=8'
    echo 'opcache.max_accelerated_files=4000'
    echo 'opcache.revalidate_freq=0'
    echo 'opcache.fast_shutdown=1'
    echo 'opcache.enable_cli=1'
    echo 'realpath_cache_size=8192K'
    echo 'realpath_cache_ttl=1200'
    #        echo 'opcache.preload=/app/config/preload.php'; \
    #        echo 'opcache.preload_user=www-data'; \
    echo "opcache.validate_timestamps=$OPCACHE_VALIDATE_TIMESTAMPS"
} >/usr/local/etc/php/conf.d/opcache-recommended.ini

# assuming that max usage of memory by process is 32 mb and assigned memory per container is 256 max child is 8
{
    echo "catch_workers_output = yes"
    echo "php_admin_value[error_log] = /proc/1/fd/2"
    echo "php_admin_flag[log_errors] = on"
    echo "php_flag[expose_php] = off"
    echo "pm = static"
    echo "pm.max_children = 8"
    echo "pm.status_path = /status"
    echo "access.format = \"[%t] %R - %u '%m %r%Q%q' %s %f PID: %p Mem: %{mega}M Mb, %{kilo}M kb Time: %d CPU: %C%%\""
    echo "[global]"
    echo "log_level = notice"
    echo "log_limit = 1024"
    echo "error_log = /proc/1/fd/2"
} >>/usr/local/etc/php-fpm.d/z-www.conf

# Set the memory limit higher so the cronjob will have enough memory to fetch and process the data.
{
    echo "error_reporting = E_ALL"
    echo "display_startup_errors = on"
    echo "display_errors = on"
    echo "date.timezone = $TIMEZONE"
    echo "memory_limit = 512M"
} >>/usr/local/etc/php/conf.d/docker-php.ini