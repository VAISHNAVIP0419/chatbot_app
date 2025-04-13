#!/bin/bash

set -e

echo "Updating system..."
sudo apt-get update && sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y curl unzip gnupg lsb-release

# ------------------------
# Install AWS CLI
# ------------------------
echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws
aws --version

# ------------------------
# Install kubectl
# ------------------------
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
kubectl version --client

# ------------------------
# Install Terraform
# ------------------------
echo "Installing Terraform..."
TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | grep -oP '"current_version":\s*"\K[0-9.]+' | head -1)
curl -LO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
terraform version

# ------------------------
# Install Trivy
# ------------------------
echo "Installing Trivy..."
sudo apt-get install -y wget
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/trivy.gpg
echo "deb [arch=amd64] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy
trivy --version

echo "✅ All tools installed successfully!"

