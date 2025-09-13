# PHP-Nginx Base Docker Image

Production-ready PHP 8.3 + Nginx alap Docker image Laravel és általános PHP alkalmazásokhoz.

## 🚀 Jellemzők

- **PHP 8.3 FPM** Alpine Linux alapon
- **Nginx** optimalizált konfigurációval
- **Supervisor** process management
- **Composer** előre telepítve
- **PHP Extensions**: MySQL, PostgreSQL, Redis, GD, Imagick, OPcache, stb.
- **Laravel támogatás** opcionális Queue Worker és Scheduler
- **Security headers** és rate limiting
- **Health check** endpoint
- Kb. **200-250MB** méret

## 📦 Telepített eszközök

### Backend eszközök
- **PHP 8.3** optimalizált OPcache beállításokkal
- **Composer** 2.x verzió
- **Nginx** 1.24 modern web szerver

### Frontend eszközök
- **Node.js** 20.x LTS verzió
- **npm** Node package manager
- **yarn** Alternatív package manager
- **pnpm** Gyors, helytakarékos package manager

### PHP kiterjesztések

### Kötelező modulok (előre telepítve)
- **Adatbázis:** pdo, pdo_mysql
- **Biztonság:** openssl, hash, session
- **Szövegkezelés:** mbstring, iconv, json
- **Képfeldolgozás:** gd, exif, fileinfo
- **XML:** libxml, simplexml, dom, xmlreader, xmlwriter, xsl
- **Fájlkezelés:** zip, zlib, fileinfo
- **Hálózat:** curl, sockets

### Opcionális modulok (előre telepítve)
- **Adatbázis:** pdo_pgsql, mysqli
- **Gyorsítótár:** redis, apcu, opcache
- **Számítások:** bcmath (pontos pénzügyi számítások)
- **Nemzetköziesítés:** intl
- **Képfeldolgozás:** imagick (alternatív)
- **HTML:** tidy (HTML tisztítás)
- **Egyéb:** soap, calendar, gettext, pcntl

### Ellenőrzés
A `/public/check-modules.php` fájl segítségével ellenőrizheted a telepített modulokat

## 🔧 Használat

### Alapértelmezett használat (Laravel nélkül)

```dockerfile
FROM mycompany/php-nginx-base:latest

COPY --chown=www-data:www-data . /var/www/html
RUN composer install --no-dev --optimize-autoloader
```

### Laravel alkalmazáshoz

```dockerfile
FROM mycompany/php-nginx-base:latest

COPY --chown=www-data:www-data . /var/www/html

RUN composer install --no-dev --optimize-autoloader \
    && php artisan storage:link \
    && php artisan optimize:clear

# Laravel Queue Worker bekapcsolása
ENV ENABLE_LARAVEL_WORKER=true
ENV QUEUE_WORKERS=4

# Laravel Scheduler bekapcsolása
ENV ENABLE_LARAVEL_SCHEDULER=true
```

## 🎛️ Környezeti változók

### Alap változók

| Változó | Alapértelmezett | Leírás |
|---------|-----------------|---------|
| `APP_ENV` | production | Alkalmazás környezet |
| `APP_DEBUG` | false | Debug mód |
| `LOG_LEVEL` | error | Log szint |
| `TZ` | UTC | Időzóna |

### Laravel Queue Worker

| Változó | Alapértelmezett | Leírás |
|---------|-----------------|---------|
| `ENABLE_LARAVEL_WORKER` | false | Queue worker bekapcsolása |
| `QUEUE_WORKERS` | 2 | Worker process-ek száma |
| `QUEUE_CONNECTION` | redis | Queue kapcsolat típusa |
| `QUEUE_SLEEP` | 3 | Sleep idő másodpercben |
| `QUEUE_TRIES` | 3 | Újrapróbálkozások száma |
| `QUEUE_TIMEOUT` | 3600 | Timeout másodpercben |

### Laravel Scheduler

| Változó | Alapértelmezett | Leírás |
|---------|-----------------|---------|
| `ENABLE_LARAVEL_SCHEDULER` | false | Scheduler bekapcsolása |

## 📁 Könyvtárstruktúra

```
/var/www/html/          # Alkalmazás root (document root: /var/www/html/public)
/var/log/nginx/         # Nginx logok
/var/log/php-fpm/       # PHP-FPM logok
/var/log/supervisor/    # Supervisor logok
```

## 🐳 Docker Compose példa

```yaml
version: '3.8'

services:
  app:
    image: mycompany/php-nginx-base:latest
    ports:
      - "8080:80"
    environment:
      - APP_ENV=production
      - ENABLE_LARAVEL_WORKER=true
      - ENABLE_LARAVEL_SCHEDULER=true
      - QUEUE_WORKERS=4
      - TZ=Europe/Budapest
    volumes:
      - ./:/var/www/html
```

## 🛠️ Testreszabás

### Custom Nginx konfiguráció

Helyezd el a saját nginx konfigurációdat:
```
.docker/nginx/default.conf
```

### Custom PHP konfiguráció

Helyezd el a saját PHP beállításaidat:
```
.docker/php/php.ini
```

## 🏗️ Build

```bash
# Build
docker build -t mycompany/php-nginx-base:latest .

# Push to registry
docker push mycompany/php-nginx-base:latest
```

## 🔍 Debugging

```bash
# Container-be belépés
docker exec -it container_name sh

# Supervisor status
supervisorctl status

# Nginx reload
nginx -s reload

# PHP-FPM reload
kill -USR2 1

# Logok megtekintése
tail -f /var/log/nginx/error.log
tail -f /var/log/php-fpm/error.log
tail -f /var/log/supervisor/laravel-worker.log
```

## ⚡ Performance tippek

1. **OPcache**: Production környezetben automatikusan optimalizálva
2. **PHP-FPM**: Dynamic process manager előre konfigurálva
3. **Nginx**: Gzip tömörítés és cache headers beállítva
4. **Alpine Linux**: Kisebb image méret

## 🔒 Biztonság

- Non-root user (www-data)
- Security headers előre konfigurálva
- Rate limiting zónák
- Veszélyes PHP funkciók letiltva production módban

## 📝 Megjegyzések

- A Laravel Worker és Scheduler csak akkor indul el, ha található `artisan` fájl
- A `/health` endpoint mindig elérhető monitoring célokra
- Static fájlok automatikusan cache-elve (30 nap)

## 🤝 Támogatott alkalmazások

- Laravel 8+
- Symfony 5+
- Vanilla PHP alkalmazások
- WordPress (kisebb módosításokkal)
- Bármilyen PHP-FPM kompatibilis alkalmazás