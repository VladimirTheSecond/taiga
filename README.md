# taiga
kanban für devops

Self-hosted [Taiga](https://www.taiga.io/) Kanban board deployed on AWS using Terraform and Ansible.

## Architecture

- **Cloud**: AWS, region `eu-central-1` (Frankfurt)
- **Compute**: Single EC2 instance (`t3.medium`, 2 vCPU / 4 GB RAM)
- **Provisioning**: Terraform
- **Configuration**: Ansible
- **Containerization**: Docker + Docker Compose
- **Reverse proxy**: Nginx with Let's Encrypt SSL

## Repository structure

...

Prerequisites:  
- ansible installed  
- ansible-galaxy collection install community.docker community.general
- terraform installed  
- terraform aws plugin  

