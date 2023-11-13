# Odoo Terraform Module

This module creates all the stack needed to run Odoo on AWS

## What will be created?

This module will creates:

* EC2 instance with the Odoo application
* The Odoo ACM Certificate and the Route53 records to get the certificates validated
* The Application Load Balancer to distribute the requisitions to Odoo Target Group
* The Odoo target group with the Odoo EC2 instance as target in the 80 port
* The DNS record to point the Odoo domain name to the Application Load Balancer
* The Security Group releasing the requisitions to needed ports

## Requirements

To run this module you have to have the DNS zone already created using Route53 because this module uses this zone
to point the Odoo DNS name to the Load Balancer that hosts Odoo Target Group.
Also, you need to have an VPC already configurated with at least two subnets to host the Odoo Load Balancer.

## How will be the cost for all the resources created by this module?

Approximate values ​​for all resources in this module using the us-east-1 region:

* EC2 - Depends of the Instance Type you chose, but using t3a.medium as minimum is ~ $27.00
* ALB - ~ $23.00
* DNS - ~ $1.00

**Total**: ~ $51.00

## How to use this module?

This is the minimum configuration you need to set to use this module:

```
# Get the AWS VPC to create the resources in
data "aws_vpc" "default_vpc" {
  default = true
}

# Get the most recent EC2 AMI for Ubuntu 22.04
data "aws_ami" "ubuntu" {
  most_recent      = true
  owners = ["099720109477"] //Owner Amazon

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Use the Module
module "ec2_instance_odoo_server" {
  source                      = "git::https://github.com/pingotecnologia/pingo-terraform//custom/odoo?ref=main"
  name_prefix                 = # Name Prefix for all resources
  ami                         = data.aws_ami.ubuntu.image_id //Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
  instance_type               = # AWS Instance type like t3a.medium
  dns_zone                    = # DNS zone to create the Records like pingotecnologia.com
  key_name                    = # Keypair to attach to the EC2 instance
  monitoring                  = false
  associate_public_ip_address = true
  vpc_id                      = data.aws_vpc.default_vpc.id
  region                      = # region to deploy the resources
  root_block_device = [{
    volume_type           = "gp3"
    encrypted             = true
    volume_size           = "100" #volume size
    delete_on_termination = true
    tags = {
      Name            = "odoo-disk0",
      tag_environment = local.environment
      tag_service     = local.service
      tag_repo        = "github.com/pingotecnologia/pingo_odoo"
    }
  }]
  odoo_version       = # Odoo Version, like 16.0
  odoo_user          = odoo #recomend always use odoo
  odoo_domain_name   = # like odoo.pingotecnologia.com
  tag_environment    = # the environment like dev, qa, prd, etc
  tag_service        = # the tag service like odoo
  tag_repo           = # the repository like github.com/pingotecnologia/pingo_odoo
}
```
