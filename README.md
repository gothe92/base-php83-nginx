# Base PHP 8.3 + Nginx Alpine Docker Image

Production-ready PHP 8.3 + Nginx Docker image based on [ServerSideUp PHP images](https://serversideup.net/open-source/docker-php/).

## Features

- **Alpine Linux 3.22** - Lightweight and secure
- **PHP 8.3 FPM** with OPcache
- **Nginx** - High performance web server
- **Redis** - Caching support
- **Node.js & npm/yarn/pnpm** - Frontend tooling
- **Git, nano** - Development tools

### PHP Extensions
- **apcu** - Memory-based caching
- **imagick** - Image processing
- **pdo_pgsql** - PostgreSQL support
- Plus all standard extensions from ServerSideUp base image

## Usage

### Docker Hub
```bash
docker pull gothe92/base-php83-nginx:latest
docker run -d -p 80:80 -v ./app:/var/www/html gothe92/base-php83-nginx
```

### Docker Compose
```yaml
services:
  web:
    image: gothe92/base-php83-nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./app:/var/www/html
    environment:
      - PHP_OPCACHE_ENABLE=1
```

### Dockerfile
```dockerfile
FROM gothe92/base-php83-nginx:latest
COPY . /var/www/html
RUN composer install --no-dev
```

## Configuration

Based on ServerSideUp PHP configuration. See [documentation](https://serversideup.net/open-source/docker-php/docs/) for customization options.

## Ports
- **80** - HTTP
- **443** - HTTPS

## User & Workdir
- **User**: `www-data` (UID: 82)  
- **Workdir**: `/var/www/html`