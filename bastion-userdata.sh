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


# Configure kubectl for EKS (for ubuntu user)
# sudo -u ubuntu aws eks update-kubeconfig --region ${region} --name ${cluster_name}

# Configure kubectl for EKS (for root user - SSM sessions)
aws eks update-kubeconfig --region ${region} --name ${cluster_name}

# Install useful tools
apt install -y git htop tree jq

# Install k9s
wget https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb && apt install ./k9s_linux_amd64.deb && rm k9s_linux_amd64.deb
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
- k9s (Kubernetes TUI)
- aws cli v2
- helm
- docker
- git, htop, tree, jq

Quick commands:
- k get nodes
- k9s
- helm list -A

===========================================

EOF

# Set up bash completion and aliases
echo 'source <(kubectl completion bash)' >> /home/ubuntu/.bashrc
echo 'alias k=kubectl' >> /home/ubuntu/.bashrc
echo 'complete -F __start_kubectl k' >> /home/ubuntu/.bashrc

# Also add for root user
echo 'source <(kubectl completion bash)' >> /root/.bashrc
echo 'alias k=kubectl' >> /root/.bashrc
echo 'complete -F __start_kubectl k' >> /root/.bashrc
