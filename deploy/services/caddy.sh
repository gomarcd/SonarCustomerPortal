#!/bin/sh
sv start php-fpm
exec env HOME=/root XDG_CONFIG_HOME=/root/.config caddy run --config /etc/caddy/Caddyfile --adapter caddyfile