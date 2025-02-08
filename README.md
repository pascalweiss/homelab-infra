# homelab-infra
Infrastructure as code for my homelab. Here I define all the services and configuration, 
that is required outside my Kubernetes cluster. 

## gitlab
I use GitLab CE to store my code and run CI/CD pipelines. It is set up using a docker-compose file with environment
variables for personal configuration. 

#### Note
The environment variables are stored in a `.env` file. You must create the file by copying the `.env_template`.    
