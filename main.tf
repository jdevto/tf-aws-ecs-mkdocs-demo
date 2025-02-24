### Data Sources (AWS Information)
# Fetch AWS-specific details

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

### Random Generator (Suffix for Naming)
# Ensures unique resource names

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

### AWS AMI (ECS Optimized Image)
# Fetches the latest Amazon ECS-optimized AMI

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

### Local Variables
# Defines region, names, and application settings

locals {
  region    = "ap-southeast-2"
  name      = "mkdocs-demo"
  base_name = "${local.name}-${random_string.suffix.result}"
  app_name  = "mkdocs"
}
