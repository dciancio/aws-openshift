locals {
  ansible_version = var.ocp_version == "3.11" ? "2.6" : "2.4"
  ec2domain = var.aws_region == "us-east-1" ? ".ec2.internal" : ""
}

# Specify the provider and access details
provider "aws" {
  region = var.aws_region
}

# Declare the data source
data "aws_availability_zones" "available" {
}

data "template_file" "sysprep-bastion" {
  template = file("./helper_scripts/sysprep-bastion.sh")
  vars = {
    rhak            = var.rhak
    rhorg           = var.rhorg
    ocp_version     = var.ocp_version
    ansible_version = local.ansible_version
    ec2domain       = local.ec2domain
  }
}

data "template_file" "sysprep-openshift" {
  template = file("./helper_scripts/sysprep-openshift.sh")
  vars = {
    rhak            = var.rhak
    rhorg           = var.rhorg
    ocp_version     = var.ocp_version
    ansible_version = local.ansible_version
    ec2domain       = local.ec2domain
  }
}

