#!/bin/bash

# Set variables for your project
CHART_NAME="my-chart"
CHART_VERSION="1.0.0"
TERRAFORM_DIR="terraform"
REPO_URL="https://charts.example.com"  # Set the repository URL
SECRET_SUFFIX="terraform-secret"      # Set the secret suffix
CONFIG_PATH="~/.kube/config"          # Set the Kubernetes config path

# Prompt the user to input the target namespace
read -p "Enter the target namespace: " TARGET_NAMESPACE

# Create a directory for your Terraform project
mkdir -p $TERRAFORM_DIR

# Use Helm to fetch the chart and extract the values.yaml file
helm fetch $REPO_URL/$CHART_NAME --version $CHART_VERSION --untar

# Move the values.yaml file to the Terraform directory
mv $CHART_NAME/values.yaml $TERRAFORM_DIR/values.local.yaml

# Generate backend.tf for Terraform Kubernetes backend configuration
cat <<EOF > $TERRAFORM_DIR/backend.tf
terraform {
  backend "kubernetes" {
    config_map_name = "terraform-state"
    secret_suffix   = "$SECRET_SUFFIX"
    config_path     = "$CONFIG_PATH"
  }
}
EOF

# Remove the directory created by helm fetch
rm -rf $CHART_NAME

# Create a main.tf file for your Terraform configuration
cat <<EOF > $TERRAFORM_DIR/main.tf
# Define your Terraform configuration here
# For example:
variable "target_namespace" {
  description = "The target Kubernetes namespace"
  default     = "$TARGET_NAMESPACE"
}

provider "helm" {
  kubernetes {
    config_path = "$CONFIG_PATH"
  }
}

locals {
  values_file = file("\${path.module}/values.local.yaml")
}

resource "helm_release" "my_release" {
  name       = "$CHART_NAME"
  repository = "$REPO_URL"
  chart      = "$CHART_NAME"
  version    = "$CHART_VERSION"
  namespace  = var.target_namespace
  values     = [local.values_file]
}
EOF

echo "Files generated successfully!"

