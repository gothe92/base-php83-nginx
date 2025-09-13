# scripts/entrypoint.sh
#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting PHP-Nginx container...${NC}"

# Environment variable defaults
export APP_ENV=${APP_ENV:-production}
export APP_DEBUG=${APP_DEBUG:-false}
export LOG_LEVEL=${LOG_LEVEL:-error}

# Laravel Queue Worker settings
export ENABLE_LARAVEL_WORKER=${ENABLE_LARAVEL_WORKER:-false}
export QUEUE_WORKERS=${QUEUE_WORKERS:-2}
export QUEUE_SLEEP=${QUEUE_SLEEP:-3}
export QUEUE_TRIES=${QUEUE_TRIES:-3}
export QUEUE_TIMEOUT=${QUEUE_TIMEOUT:-3600}
export QUEUE_CONNECTION=${QUEUE_CONNECTION:-redis}

# Laravel Scheduler settings
export ENABLE_LARAVEL_SCHEDULER=${ENABLE_LARAVEL_SCHEDULER:-false}

# Set timezone if provided
if [ ! -z "$TZ" ]; then
    echo -e "${YELLOW}Setting timezone to $TZ${NC}"
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
    echo "date.timezone = $TZ" > /usr/local/etc/php/conf.d/timezone.ini
fi

# Create necessary directories if they don't exist
mkdir -p /var/www/html/storage/logs 2>/dev/null || true
mkdir -p /var/www/html/storage/framework/{sessions,views,cache} 2>/dev/null || true
mkdir -p /var/www/html/bootstrap/cache 2>/dev/null || true

# Set permissions
if [ "$APP_ENV" != "local" ]; then
    echo -e "${YELLOW}Setting production permissions...${NC}"
    chown -R www-data:www-data /var/www/html
    find /var/www/html -type f -exec chmod 644 {} \;
    find /var/www/html -type d -exec chmod 755 {} \;
    
    # Storage needs to be writable
    if [ -d "/var/www/html/storage" ]; then
        chmod -R 775 /var/www/html/storage
        chmod -R 775 /var/www/html/bootstrap/cache
    fi
fi

# Laravel specific optimizations (only in production)
if [ "$APP_ENV" = "production" ] && [ -f "/var/www/html/artisan" ]; then
    echo -e "${YELLOW}Running Laravel optimizations...${NC}"
    php artisan config:cache 2>/dev/null || true
    php artisan route:cache 2>/dev/null || true
    php artisan view:cache 2>/dev/null || true
fi

# Node.js build process (if package.json exists)
if [ -f "/var/www/html/package.json" ]; then
    echo -e "${YELLOW}Node.js project detected${NC}"
    
    # Install dependencies if node_modules doesn't exist
    if [ ! -d "/var/www/html/node_modules" ]; then
        echo -e "${YELLOW}Installing Node.js dependencies...${NC}"
        cd /var/www/html
        
        # Check which package manager to use
        if [ -f "yarn.lock" ]; then
            echo -e "${GREEN}Using Yarn${NC}"
            yarn install --frozen-lockfile 2>/dev/null || yarn install
        elif [ -f "pnpm-lock.yaml" ]; then
            echo -e "${GREEN}Using pnpm${NC}"
            pnpm install --frozen-lockfile 2>/dev/null || pnpm install
        else
            echo -e "${GREEN}Using npm${NC}"
            npm ci 2>/dev/null || npm install
        fi
    fi
    
    # Run build in production
    if [ "$APP_ENV" = "production" ]; then
        echo -e "${YELLOW}Building frontend assets...${NC}"
        if [ -f "yarn.lock" ]; then
            yarn build 2>/dev/null || yarn production 2>/dev/null || true
        elif [ -f "pnpm-lock.yaml" ]; then
            pnpm build 2>/dev/null || pnpm production 2>/dev/null || true
        else
            npm run build 2>/dev/null || npm run production 2>/dev/null || true
        fi
    fi
fi

# Enable Laravel Queue Worker if requested
if [ "$ENABLE_LARAVEL_WORKER" = "true" ] && [ -f "/var/www/html/artisan" ]; then
    echo -e "${GREEN}Enabling Laravel Queue Worker...${NC}"
    echo -e "${YELLOW}  Workers: $QUEUE_WORKERS${NC}"
    echo -e "${YELLOW}  Connection: $QUEUE_CONNECTION${NC}"
    echo -e "${YELLOW}  Sleep: ${QUEUE_SLEEP}s, Tries: $QUEUE_TRIES, Timeout: ${QUEUE_TIMEOUT}s${NC}"
    
    # Update supervisor environment variables
    sed -i "s/%(ENV_QUEUE_WORKERS)s/$QUEUE_WORKERS/g" /etc/supervisor/conf.d/supervisord.conf
    sed -i "s/%(ENV_QUEUE_SLEEP)s/$QUEUE_SLEEP/g" /etc/supervisor/conf.d/supervisord.conf
    sed -i "s/%(ENV_QUEUE_TRIES)s/$QUEUE_TRIES/g" /etc/supervisor/conf.d/supervisord.conf
    sed -i "s/%(ENV_QUEUE_TIMEOUT)s/$QUEUE_TIMEOUT/g" /etc/supervisor/conf.d/supervisord.conf
    
    # Enable autostart for worker
    sed -i 's/\[program:laravel-worker\]/[program:laravel-worker]/g; /\[program:laravel-worker\]/,/\[program:/ s/autostart=false/autostart=true/' /etc/supervisor/conf.d/supervisord.conf
else
    echo -e "${YELLOW}Laravel Queue Worker is disabled (set ENABLE_LARAVEL_WORKER=true to enable)${NC}"
fi

# Enable Laravel Scheduler if requested
if [ "$ENABLE_LARAVEL_SCHEDULER" = "true" ] && [ -f "/var/www/html/artisan" ]; then
    echo -e "${GREEN}Enabling Laravel Scheduler...${NC}"
    
    # Enable autostart for scheduler
    sed -i 's/\[program:laravel-scheduler\]/[program:laravel-scheduler]/g; /\[program:laravel-scheduler\]/,/\[program:/ s/autostart=false/autostart=true/' /etc/supervisor/conf.d/supervisord.conf
else
    echo -e "${YELLOW}Laravel Scheduler is disabled (set ENABLE_LARAVEL_SCHEDULER=true to enable)${NC}"
fi

# Custom nginx config if provided
if [ -f "/var/www/html/.docker/nginx/default.conf" ]; then
    echo -e "${YELLOW}Using custom nginx configuration${NC}"
    cp /var/www/html/.docker/nginx/default.conf /etc/nginx/http.d/default.conf
fi

# Custom PHP config if provided
if [ -f "/var/www/html/.docker/php/php.ini" ]; then
    echo -e "${YELLOW}Using custom PHP configuration${NC}"
    cp /var/www/html/.docker/php/php.ini /usr/local/etc/php/conf.d/99-custom.ini
fi

# Test nginx configuration
nginx -t

# Test PHP-FPM configuration
php-fpm -t

echo -e "${GREEN}Container ready!${NC}"
echo -e "${GREEN}PHP Version: $(php -v | head -n 1)${NC}"
echo -e "${GREEN}Nginx Version: $(nginx -v 2>&1 | cut -d' ' -f3 | cut -d'/' -f2)${NC}"

# Show Laravel services status
if [ -f "/var/www/html/artisan" ]; then
    echo -e "${GREEN}Laravel detected${NC}"
    [ "$ENABLE_LARAVEL_WORKER" = "true" ] && echo -e "${GREEN}✓ Queue Worker enabled${NC}" || echo -e "${YELLOW}✗ Queue Worker disabled${NC}"
    [ "$ENABLE_LARAVEL_SCHEDULER" = "true" ] && echo -e "${GREEN}✓ Scheduler enabled${NC}" || echo -e "${YELLOW}✗ Scheduler disabled${NC}"
fi

# Execute the main command
exec "$@"