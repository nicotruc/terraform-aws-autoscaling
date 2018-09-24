variable "aws_region" {}

variable "aws_profile" {}

variable "vpc_name" {
  type        = "string"
  description = "VPC Name"
}

variable "app_name" {
  type        = "string"
  description = "Name of the application"
}

variable "app_tags" {
  default     = {}
  description = "Set of tags to apply to the application"
}

variable "app_count" {
  default     = 1
  description = "Number of application instances desired"
}

variable "app_instance_type" {
  default     = "t2.micro"
  description = "Type of instance to use for the application"
}

variable "app_key_name" {
  type        = "string"
  description = "Name of the keypair to use for the application"
}

variable "app_root_block_device" {
  default = {
    volume_type = "gp2"
    volume_size = 20
  }

  description = "An EBS block device block definition to use by the application"
}
