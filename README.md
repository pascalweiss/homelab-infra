# Homelab Infrastructure

This repository contains the infrastructure as code for my homelab, defining all the services and configurations required outside my Kubernetes cluster.

## GitLab CE with Traefik Reverse Proxy

This setup provides a complete GitLab CE instance with Traefik as a reverse proxy, handling secure TLS connections.

### Architecture Overview

- **Traefik (v3.3.4)**: Acts as a reverse proxy for GitLab
- **GitLab CE (v17.10.1)**: The GitLab Community Edition instance
- **Docker Compose**: Orchestrates the containers and networking

### Key Features

#### Traefik as Reverse Proxy

Traefik functions as a reverse proxy for GitLab, handling:
- Traffic routing based on hostname
- TLS termination for HTTPS connections
- Redirection from HTTP to HTTPS for enhanced security
- Exposing GitLab services via a clean URL

#### TLS Encryption

All traffic to GitLab is encrypted using TLS:
- Traefik manages the TLS certificates
- TLS certificates are mounted from the host into the Traefik container
- Secure headers are applied through middleware configurations
- Automatic redirection from HTTP to HTTPS using the `redirectToHttps` middleware

#### Self-Signed Certificates

The setup uses self-signed certificates that can be created with the included script:
- Run `./gitlab/generate-cert.sh` to create certificates
- The script generates a certificate for the hostname defined in your `.env` file
- Certificates are stored in `gitlab/traefik/certs/`
- Default validity is 365 days (configurable via `SSL_CERT_EXPIRY_DAYS` environment variable)

### Getting Started

1. Clone this repository
2. Create a `.env` file based on the `.env_template`
3. Generate self-signed certificates:
   ```
   cd gitlab
   ./generate-cert.sh
   ```
4. Start the services:
   ```
   cd gitlab
   docker-compose up -d
   ```

### Configuration

The setup is highly configurable through environment variables in the `.env` file:
- `GITLAB_HOSTNAME`: The hostname for your GitLab instance
- `GITLAB_SSH_PORT`: SSH port for Git operations
- `TRAEFIK_DASHBOARD_HOST`: Hostname for the Traefik dashboard
- `TRAEFIK_NETWORK`: Docker network name for communication
- `GITLAB_PERSISTENCE`: Path for GitLab persistent storage
- `GITLAB_SHM_SIZE`: Shared memory size for GitLab

Email (SMTP) configuration is also available through environment variables for GitLab notifications.

### Access

- GitLab: https://[GITLAB_HOSTNAME]
- Traefik Dashboard: http://[TRAEFIK_DASHBOARD_HOST]:8080

### Note

When using self-signed certificates, you'll need to add them to your trusted certificates in your browser or accept the security warning.
