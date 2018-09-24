### Backend definition

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

### Module Main

######################################################################
## Fetch AWS data
######################################################################

module "discovery" {
  source              = "github.com/Lowess/terraform-aws-discovery"
  aws_region          = "${var.aws_region}"
  vpc_name            = "${var.vpc_name}"
  ec2_ami_names       = ["api-002"]
  ec2_security_groups = ["ops"]
}

locals {
  app_ami_id  = "${module.discovery.images_id[0]}"
  app_subnets = "${module.discovery.public_subnets}"
  ops_sg      = "${module.discovery.security_groups_json["ops"]}"
}

data "http" "whatismyip" {
  url = "http://icanhazip.com"
}
