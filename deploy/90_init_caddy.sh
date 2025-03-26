#!/bin/bash
set -euf -o pipefail

if [ "${ENABLE_SSL:-false}" = "true" ]; then
    PORTAL_DOMAIN="$PORTAL_DOMAIN"
else
    PORTAL_DOMAIN="http://$PORTAL_DOMAIN"
fi

export PORTAL_DOMAIN
envsubst '$PORTAL_DOMAIN' < /etc/caddy/Caddyfile.template > /etc/caddy/Caddyfile