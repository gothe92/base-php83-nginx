FROM serversideup/php:8.3-fpm-nginx-alpine

USER root

ENV PHP_OPCACHE_ENABLE=1

RUN apk update && apk add --no-cache \
    nodejs \
    npm

RUN rm -rf /tmp/* /var/cache/apk/*

USER www-data
WORKDIR /var/www/html
