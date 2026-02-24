terraform {
  backend "s3" {
    bucket         = "platform-tf-state"
    key            = "lk/02-tenants/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

# provider "rancher2" { ... }
# provider "harvester" { ... }

# module "team_alpha_cluster" {
#   source       = "../../../modules/workloads/k8s_cluster"
#   cluster_name = "lk-prod-1"
#   node_count   = 3
# }

# module "team_beta_db" {
#   source       = "../../../modules/workloads/pg_ha"
#   cluster_name = "pg-lk-1"
# }
