#!/usr/bin/env bash
set -e

echo "🏗️ Setting up Terraform and Terragrunt..."

# Check if Terraform is installed
if ! command -v terraform &>/dev/null; then
  echo "❌ Terraform not found. Please install it first with 'brew install terraform'"
  exit 1
fi

# Check if Terragrunt is installed
if ! command -v terragrunt &>/dev/null; then
  echo "❌ Terragrunt not found. Please install it first with 'brew install terragrunt'"
  exit 1
fi

# Get versions
TERRAFORM_VERSION=$(terraform version | head -n1 | cut -d' ' -f2)
TERRAGRUNT_VERSION=$(terragrunt --version | head -n1 | cut -d' ' -f3)

echo "✅ Terraform found: $TERRAFORM_VERSION"
echo "✅ Terragrunt found: $TERRAGRUNT_VERSION"

# Create terraform directory structure if it doesn't exist
TERRAFORM_DIR="$HOME/.terraform.d"
if [[ ! -d "$TERRAFORM_DIR" ]]; then
  echo "📁 Creating Terraform configuration directory: $TERRAFORM_DIR"
  mkdir -p "$TERRAFORM_DIR"
fi

echo "📝 Terraform and Terragrunt features:"
echo "   • Infrastructure as Code with declarative configuration"
echo "   • Multi-cloud support (AWS, Azure, GCP, 100+ providers)"
echo "   • State management and change planning"
echo "   • Modular and reusable infrastructure components"
echo "   • DRY configurations with Terragrunt"
echo "   • Remote state management and locking"

echo ""
echo "💡 Common usage patterns:"
echo "   • Initialize: terraform init"
echo "   • Plan changes: terraform plan"
echo "   • Apply changes: terraform apply"
echo "   • Destroy resources: terraform destroy"
echo "   • With Terragrunt: terragrunt plan|apply|destroy"

echo ""
echo "🔧 Recommended setup:"
echo "   • Store Terraform files in version control"
echo "   • Use remote state (S3, Terraform Cloud, etc.)"
echo "   • Organize code with modules and environments"
echo "   • Use Terragrunt for DRY configurations"

echo ""
echo "📁 Suggested directory structure:"
echo "   terraform/"
echo "   ├── modules/          # Reusable modules"
echo "   ├── environments/"
echo "   │   ├── dev/"
echo "   │   ├── staging/"
echo "   │   └── prod/"
echo "   └── terragrunt.hcl    # Terragrunt configuration"

echo ""
echo "✅ Terraform and Terragrunt setup complete!"
echo "💡 Ready for Infrastructure as Code workflows!"