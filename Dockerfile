FROM caddy:2.9.1@sha256:cd261fc62394f1ff0b44f16eb1d202b4e71d5365c9ec866a4f1a9c5a52da9352 AS caddy
FROM phusion/baseimage:jammy-1.0.1 AS base

ENV XDG_CONFIG_HOME /config
ENV XDG_DATA_HOME /data
ENV LC_ALL C.UTF-8

ARG PHP_VERSION=8.2

# Install PHP and dependencies
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

COPY --from=caddy /usr/bin/caddy /usr/bin/caddy

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
RUN mkdir -p /etc/service/caddy
COPY deploy/services/php-fpm.sh /etc/service/php-fpm/run
COPY deploy/services/caddy.sh /etc/service/caddy/run

VOLUME /var/www/html/storage
EXPOSE 80 443