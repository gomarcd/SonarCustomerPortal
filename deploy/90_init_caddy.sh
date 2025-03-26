#!/bin/bash
set -euf -o pipefail

envsubst '$PORTAL_DOMAIN $ENABLE_SSL' < /etc/caddy/Caddyfile.template > /etc/caddy/Caddyfile