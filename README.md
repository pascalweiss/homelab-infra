# Homelab Infrastructure

This repository contains the infrastructure as code for my homelab, defining all the services and configurations required outside my Kubernetes cluster.

## Project Structure

The project is organized into service-specific directories with a main docker-compose file at the root:

```
docker-compose.yaml     # Main compose file that includes all services
.env                    # Environment variables (create from .env_template)
traefik/                # Traefik reverse proxy configuration
  ├── traefik-compose.yaml
  ├── certs/            # SSL certificates
  └── config/           # Traefik configuration
gitlab/                 # GitLab service configuration
  ├── gitlab-compose.yaml
  └── generate-cert.sh  # Script to generate SSL certificates
whoami/                 # Whoami service (simple diagnostic container)
  └── whoami-compose.yaml
```

## Services Overview

This setup provides:

- **Traefik (v3.3.4)**: Acts as a reverse proxy for all services
- **GitLab CE (v17.10.1)**: A complete GitLab Community Edition instance
- **Whoami**: A simple diagnostic service that displays request information
- **Docker Compose**: Orchestrates the containers and networking

## Key Features

### Modular Docker Compose Structure

The project uses Docker Compose's `include` directive to maintain a clean, modular structure:
- Each service has its own compose file
- Services can be developed and maintained independently
- The main docker-compose.yaml ties everything together

### Traefik as Reverse Proxy

Traefik functions as a reverse proxy for all services, handling:
- Traffic routing based on hostname
- TLS termination for HTTPS connections
- Exposing services via clean URLs

### TLS Encryption

All traffic to GitLab can be encrypted using TLS:
- Traefik manages the TLS certificates
- TLS certificates are mounted from the host into the Traefik container
- Secure headers are available through middleware configurations
- GitLab internally manages redirection from HTTP to HTTPS

Note: GitLab is configured to redirect HTTP traffic to HTTPS by default due to its internal configuration.

### Self-Signed Certificates

The setup uses self-signed certificates that can be created with the included script:
- Run `./gitlab/generate-cert.sh` to create certificates
- The script generates a certificate for the hostname defined in your `.env` file
- Certificates are stored in `traefik/certs/`
- Default validity is 365 days (configurable via `SSL_CERT_EXPIRY_DAYS` environment variable)

## Getting Started

1. Clone this repository
2. Create a `.env` file based on the `.env_template`
3. Generate self-signed certificates:
   ```
   cd gitlab
   ./generate-cert.sh
   ```
4. Start all services:
   ```
   docker compose up -d
   ```

## Configuration

The setup is highly configurable through environment variables in the `.env` file:
- `GITLAB_HOSTNAME`: The hostname for your GitLab instance
- `GITLAB_SSH_PORT`: SSH port for Git operations
- `TRAEFIK_DASHBOARD_HOST`: Hostname for the Traefik dashboard
- `TRAEFIK_NETWORK`: Docker network name for communication
- `GITLAB_PERSISTENCE`: Path for GitLab persistent storage
- `GITLAB_SHM_SIZE`: Shared memory size for GitLab

Email (SMTP) configuration is also available through environment variables for GitLab notifications.

## Service Management

### Starting and Stopping Services

Start all services:
```
docker compose up -d
```

Stop all services:
```
docker compose down
```

View logs for all services:
```
docker compose logs -f
```

View logs for a specific service:
```
docker compose logs -f [service_name]
```

### Service-Specific Management

If you want to manage services individually, you can use:
```
docker compose -f [service_directory]/[service]-compose.yaml up -d
```

For example, to start only the whoami service:
```
docker compose -f whoami/whoami-compose.yaml up -d
```

## Access

- GitLab: https://[GITLAB_HOSTNAME] (HTTP access will be redirected to HTTPS by GitLab)
- Traefik Dashboard: http://[TRAEFIK_DASHBOARD_HOST]:8080
- Whoami: http://whoami.[TRAEFIK_DASHBOARD_HOST]

## Note

When using self-signed certificates, you'll need to add them to your trusted certificates in your browser or accept the security warning.
