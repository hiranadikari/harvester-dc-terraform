terraform {
  backend "s3" {
    bucket         = "platform-tf-state"
    key            = "lk/01-management/terraform.tfstate"
    region         = "ap-south-1" # Or your appropriate region
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

# 1. Provide Harvester or Rancher details (derived from 00-bootstrap)
# data "terraform_remote_state" "bootstrap" {
#   backend = "local" # or whatever 00-bootstrap uses
#   config  = { path = "../00-bootstrap/terraform.tfstate" }
# }

# provider "rancher2" {
#   api_url  = data.terraform_remote_state.bootstrap.outputs.rancher_url
#   token_key = var.rancher_admin_token
#   insecure = true
# }

# 2. Call modules for Management Tier
# module "networking" {
#   source = "../../../modules/management/networking"
# }

# module "storage" {
#   source = "../../../modules/management/storage"
# }

# module "rbac" {
#   source = "../../../modules/management/rbac"
# }
