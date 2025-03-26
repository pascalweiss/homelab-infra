#!/bin/bash

# Load environment variables from .env
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "Error: .env file not found"
    exit 1
fi

# Check if GITLAB_HOSTNAME is set
if [ -z "$GITLAB_HOSTNAME" ]; then
    echo "Error: GITLAB_HOSTNAME is not defined in .env"
    exit 1
fi

# Set default certificate expiry if not set
if [ -z "$SSL_CERT_EXPIRY_DAYS" ]; then
    SSL_CERT_EXPIRY_DAYS=365
    echo "Warning: SSL_CERT_EXPIRY_DAYS not set, using default value of 365 days"
fi

# Create certificates directory if it doesn't exist
mkdir -p traefik/certs

# Generate the certificate
openssl req -x509 -nodes -days ${SSL_CERT_EXPIRY_DAYS} -newkey rsa:2048 \
    -keyout traefik/certs/gitlab.key \
    -out traefik/certs/gitlab.crt \
    -subj "/CN=${GITLAB_HOSTNAME}" \
    -addext "subjectAltName=DNS:${GITLAB_HOSTNAME}"

# Set correct permissions
chmod 600 traefik/certs/gitlab.key
chmod 644 traefik/certs/gitlab.crt

echo "SSL certificate successfully generated for ${GITLAB_HOSTNAME}"
echo "Certificate: traefik/certs/gitlab.crt"
echo "Private key: traefik/certs/gitlab.key"
echo "Certificate will expire in ${SSL_CERT_EXPIRY_DAYS} days" 