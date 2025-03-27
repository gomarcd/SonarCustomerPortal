#!/bin/sh
export HOME=/root
export XDG_CONFIG_HOME=/root/.config
sv start php-fpm
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile