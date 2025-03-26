#!/bin/sh
sv start php-fpm
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile