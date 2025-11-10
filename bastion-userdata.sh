#!/bin/bash
apt update -y

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt install -y unzip
unzip awscliv2.zip
sudo ./aws/install

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install docker
apt install -y docker.io
systemctl start docker
systemctl enable docker
usermod -a -G docker ubuntu

# Configure kubectl for EKS
sudo -u ubuntu aws eks update-kubeconfig --region ${region} --name ${cluster_name}

# Install useful tools
apt install -y git htop tree jq

# Create welcome message
cat << 'EOF' > /etc/motd

===========================================
    EKS Bastion Host - Administrator
===========================================

Cluster: ${cluster_name}
Region: ${region}
OS: Ubuntu 22.04 LTS

Available tools:
- kubectl (configured for EKS)
- aws cli v2
- helm
- docker
- git, htop, tree, jq

Quick commands:
- kubectl get nodes
- kubectl get pods -A
- helm list -A

===========================================

EOF

# Set up bash completion
echo 'source <(kubectl completion bash)' >> /home/ubuntu/.bashrc
echo 'alias k=kubectl' >> /home/ubuntu/.bashrc
echo 'complete -F __start_kubectl k' >> /home/ubuntu/.bashrc
