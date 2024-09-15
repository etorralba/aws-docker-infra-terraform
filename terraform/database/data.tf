// Network state
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "${var.account_id}-tf-state"
    key    = "terraform.${var.main_organization}_network.tfstate"
    region = var.region
  }
}