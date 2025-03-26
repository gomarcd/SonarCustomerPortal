FROM phusion/baseimage:jammy-1.0.1 AS base

ENV LC_ALL C.UTF-8

ARG PHP_VERSION=8.2

RUN add-apt-repository ppa:ondrej/php \
 && install_clean \
      gettext \
      php${PHP_VERSION}-fpm \
      php${PHP_VERSION}-bcmath \
      php${PHP_VERSION}-curl \
      php${PHP_VERSION}-gmp \
      php${PHP_VERSION}-mbstring \
      php${PHP_VERSION}-sqlite3 \
      php${PHP_VERSION}-zip \
      php${PHP_VERSION}-dom \
      unzip \
      curl

RUN curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
 && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list \
 && install_clean caddy

WORKDIR /var/www/html

COPY --chown=www-data --from=composer:2.5.8 /usr/bin/composer /tmp/composer
COPY composer.json composer.lock ./
RUN mkdir -p vendor \
 && chown www-data:www-data vendor \
 && COMPOSER_CACHE_DIR=/dev/null setuser www-data /tmp/composer install --no-dev --no-interaction --no-scripts --no-autoloader

COPY --chown=www-data . .

RUN COMPOSER_CACHE_DIR=/dev/null setuser www-data /tmp/composer install --no-dev --no-interaction --no-scripts --classmap-authoritative \
 && rm -rf /tmp/composer

COPY deploy/conf/caddy/Caddyfile.template /etc/caddy/Caddyfile.template
COPY deploy/conf/php-fpm/ /etc/php/8.2/fpm/
COPY deploy/conf/cron.d/* /etc/cron.d/
RUN chmod -R go-w /etc/cron.d
RUN mkdir -p /etc/my_init.d
COPY deploy/*.sh /etc/my_init.d/
RUN mkdir /etc/service/php-fpm
COPY deploy/services/php-fpm.sh /etc/service/php-fpm/run
RUN mkdir /etc/service/caddy
COPY deploy/services/caddy.sh /etc/service/caddy/run
RUN chmod +x /etc/service/caddy/run

VOLUME /var/www/html/storage
EXPOSE 80 443