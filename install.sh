#!/usr/bin/env bash
set -euo pipefail

if [ "$UID" != 0 ]; then
    echo "This must be run as root."
    exit 1
fi

if ! [ -x "$(command -v docker)" ]; then
    echo "### docker is not installed, installing it now..."
    apt-get update
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
fi

if [ -f .env ]; then
    read -p "### WARNING: Your environment appears to already be set up. Set it up again? [y/N] " -i n -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1;

    docker compose stop
    sed -i '/API_PASSWORD=/d' .env

    source .env
fi

APP_KEY="base64:$(head -c32 /dev/urandom | base64)";

read -ep "Enter your portal domain name (e.g. portal.example.com): " -i "${PORTAL_DOMAIN:-}" PORTAL_DOMAIN
read -ep "Enter Your API Username: " -i "${API_USERNAME:-}" API_USERNAME
read -esp "Enter Your API Password (output will not be displayed): " API_PASSWORD
echo
read -ep "Enter Your Instance URL (e.g. https://example.sonar.software): " -i "${SONAR_URL:-}" SONAR_URL

read -p "Would you like to enable SSL? [y/N] " -i n -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ENABLE_SSL="true"
else
    ENABLE_SSL="false"
fi

if lsof -Pi -sTCP:LISTEN | grep -P ':(80|443)[^0-9]' >/dev/null; then
    read -p "Port 80 and/or 443 is currently in use. Do you wish to continue anyway? [y/N] " -i n -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

TRIMMED_SONAR_URL=$(echo "$SONAR_URL" | sed 's:/*$::')

cat <<- EOF > ".env"
    APP_KEY=$APP_KEY
    PORTAL_DOMAIN=$PORTAL_DOMAIN
    API_USERNAME=$API_USERNAME
    API_PASSWORD=$API_PASSWORD
    SONAR_URL=$TRIMMED_SONAR_URL
    ENABLE_SSL=$ENABLE_SSL
EOF


export APP_KEY PORTAL_DOMAIN API_USERNAME API_PASSWORD SONAR_URL ENABLE_SSL

docker pull sonarsoftware/customerportal:stable

docker compose up -d

until [ "$(docker inspect -f {{.State.Running}} sonar-customerportal)" == "true" ]; do
    sleep 0.1
done

echo "### The app key is: $APP_KEY";
echo "### Back this up somewhere in case you need it."

docker exec sonar-customerportal sh -c "/etc/my_init.d/99_init_laravel.sh && \
    cd /var/www/html && \
    setuser www-data php artisan sonar:settingskey"

if [ "$ENABLE_SSL" = "true" ]; then
    echo "### Navigate to https://$PORTAL_DOMAIN/settings and use the above settings key to configure your portal."
else
    echo "### Navigate to http://$PORTAL_DOMAIN/settings and use the above settings key to configure your portal. As you selected not to enable SSL here, make sure you configure your existing infrastructure / reverse proxy for SSL."
fi