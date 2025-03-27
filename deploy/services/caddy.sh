#!/bin/sh
sv start php-fpm
exec env HOME=/root caddy run --config /etc/caddy/Caddyfile --adapter caddyfile