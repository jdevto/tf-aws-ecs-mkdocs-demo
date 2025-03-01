################################################################################
# VPC
################################################################################

module "vpc" {
  source = "tfstack/vpc/aws"

  region             = local.region
  vpc_name           = local.name
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = data.aws_availability_zones.available.names

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  eic_subnet = "private"

  jumphost_instance_create = false
  create_igw               = true
  ngw_type                 = "single"
}
