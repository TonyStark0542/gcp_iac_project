#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# 1. Ask for the new daily Project ID
echo "===================================================="
echo "      GCP 8-HOUR LAB AUTOMATION BOOTSTRAPPER        "
echo "===================================================="
read -p "Enter today's GCP Project ID: " NEW_PROJECT_ID

if [ -z "$NEW_PROJECT_ID" ]; then
    echo "❌ Project ID cannot be empty. Exiting."
    exit 1
fi

# 2. Authenticate the User and the Application Credentials
echo -e "\nStep 1: Authenticating your user profile..."
gcloud auth login --no-launch-browser

echo -e "\nStep 2: Authenticating Application Default Credentials (Terraform)..."
gcloud auth application-default login --no-launch-browser

# Set the default project for the gcloud CLI tool
gcloud config set project "$NEW_PROJECT_ID"

# 3. Clean up yesterday's ghost state data
echo -e "\nStep 3: Purging yesterday's ghost state and lock files..."
rm -rf .terraform/ .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup

echo -e "\nStep 4: Creating fresh local terraform.tfvars file..."
# 1. Ask gcloud for the active account email
ACTIVE_EMAIL=$(gcloud config get-value account)
# 2. Extract just the username before the @ symbol
CLEAN_USER=$(echo "$ACTIVE_EMAIL" | cut -d'@' -f1)

# 3. Write both to your local tfvars file
echo "gcp_project_id = \"$NEW_PROJECT_ID\"" > terraform.tfvars
echo "gcp_username   = \"$CLEAN_USER\"" >> terraform.tfvars

# 5. Activate Virtual Environment and Initialize Infrastructure
echo -e "\nStep 5: Bootstrapping local environments..."
if [ -d ".venv" ]; then
    source .venv/bin/activate
    echo "✅ Python virtual environment activated."
else
    echo "⚠️ .venv not found. Make sure to create it later."
fi

echo -e "\nInitializing Terraform for the new project..."
terraform init

echo -e "\nExecuting Terraform Plan..."
terraform plan

echo "===================================================="
echo " Setup Complete! Review the plan above."
echo " Run 'terraform apply' to deploy your multi-OS cluster."
echo "===================================================="