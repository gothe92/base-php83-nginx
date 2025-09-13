# base-php-nginx/Dockerfile
FROM php:8.3-fpm-alpine

# Verzió változók
ENV NGINX_VERSION=1.28.0-r3
ENV SUPERVISOR_VERSION=4.2.5-r5

# ========================================
# Alapvető csomagok és Nginx telepítése
# ========================================
RUN apk update && apk add --no-cache \
    nginx=${NGINX_VERSION} \
    supervisor=${SUPERVISOR_VERSION} \
    curl \
    zip \
    unzip \
    git \
    bash \
    vim \
    tzdata \
    # Node.js és npm
    nodejs \
    npm \
    # Hálózat és biztonság
    openssl \
    ca-certificates \
    # Képfeldolgozás runtime
    imagemagick \
    imagemagick-libs \
    # XML feldolgozás runtime
    libxml2 \
    libxslt \
    # Egyéb runtime library-k
    icu-libs \
    libpng \
    libjpeg-turbo \
    freetype \
    libzip \
    oniguruma \
    postgresql-libs \
    # HTML tisztítás runtime
    tidyhtml-libs \
    # Gettext runtime
    gettext

# ========================================
# PHP kiterjesztések build függőségei
# ========================================
RUN apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    linux-headers \
    # Képfeldolgozás dev
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    imagemagick-dev \
    # XML és HTML dev
    libxml2-dev \
    libxslt-dev \
    tidyhtml-dev \
    # Adatbázis dev
    postgresql-dev \
    # Egyéb dev
    libzip-dev \
    oniguruma-dev \
    icu-dev \
    openssl-dev \
    curl-dev \
    # Gettext dev
    gettext-dev

# ========================================
# PHP Core kiterjesztések telepítése
# ========================================
# GD konfigurálása és telepítése
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-install gd

# PHP kiterjesztések telepítése
RUN docker-php-ext-install -j$(nproc) \
        # === KÖTELEZŐ MODULOK === \
        # Adatbázis
        pdo \
        pdo_mysql \
        # Biztonság és munkamenet
        session \
        # Szöveg és karakterkódolás
        mbstring \
        # Képfeldolgozás
        exif \
        # XML feldolgozás (alapvető támogatás)
        dom \
        simplexml \
        # Fájlkezelés
        zip \
        fileinfo \
        # Hálózat
        curl \
        sockets \
        # === OPCIONÁLIS DE AJÁNLOTT === \
        pdo_pgsql \
        mysqli \
        bcmath \
        intl \
        opcache \
        pcntl \
        soap \
        calendar \
        gettext

# JSON és egyéb beépített támogatás biztosítása
RUN docker-php-ext-install -j$(nproc) \
        ctype \
        filter

# ========================================
# PECL kiterjesztések telepítése
# ========================================

# Redis telepítése (opcionális de ajánlott - gyorsítótár)
RUN pecl install redis \
    && docker-php-ext-enable redis

# APCu telepítése (memória alapú gyorsítótár)
RUN pecl install apcu \
    && docker-php-ext-enable apcu

# Imagick telepítése (alternatív képfeldolgozás)
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# ========================================
# Takarítás - Build függőségek eltávolítása
# ========================================
RUN apk del .build-deps \
    && rm -rf /tmp/* /var/cache/apk/*

# ========================================
# Composer telepítése
# ========================================
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# ========================================
# Node.js globális csomagok telepítése (opcionális)
# ========================================
RUN npm install -g \
    yarn \
    pnpm \
    && npm cache clean --force

# ========================================
# Könyvtárak létrehozása
# ========================================
RUN mkdir -p /var/www/html \
    && mkdir -p /var/log/nginx \
    && mkdir -p /var/log/php-fpm \
    && mkdir -p /var/log/supervisor \
    && mkdir -p /run/nginx \
    && mkdir -p /run/php-fpm

# ========================================
# Konfigurációs fájlok másolása
# ========================================
# Nginx konfiguráció
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/default.conf /etc/nginx/http.d/default.conf

# PHP konfiguráció
COPY config/php.ini /usr/local/etc/php/php.ini
COPY config/www.conf /usr/local/etc/php-fpm.d/www.conf

# Supervisor konfiguráció
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Entrypoint script
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ========================================
# Felhasználó és jogosultságok
# ========================================
RUN addgroup -g 1000 -S www-data 2>/dev/null || true \
    && adduser -u 1000 -D -S -G www-data www-data 2>/dev/null || true \
    && chown -R www-data:www-data /var/www/html \
    && chown -R www-data:www-data /var/log/nginx \
    && chown -R www-data:www-data /var/log/php-fpm \
    && chown -R www-data:www-data /run/nginx \
    && chown -R www-data:www-data /run/php-fpm

# ========================================
# Munkakörnyezet és portok
# ========================================
WORKDIR /var/www/html
EXPOSE 80 443

# ========================================
# Health check
# ========================================
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# ========================================
# Entrypoint és CMD
# ========================================
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]