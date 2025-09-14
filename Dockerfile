FROM serversideup/php:8.3-fpm-nginx-alpine

USER root

RUN apk update && apk add --no-cache \
    nodejs \
    npm

RUN install-php-extensions \
    apcu \
    imagick \
    pdo_pgsql

RUN npm install -g \
    && npm cache clean --force

RUN rm -rf /tmp/* /var/cache/apk/*

USER www-data
WORKDIR /var/www/html