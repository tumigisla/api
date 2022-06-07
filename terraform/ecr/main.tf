locals {
  aws_region = "eu-west-1"
  common_tags = tomap({
    "Owner"         = "DevOps",
    "Business Unit" = "IT",
    "Customer"      = "General",
    "terraform"     = "true",
    "state"         = "ecr"
  })
  ecr_repositories = ["api"]
}


terraform {
  backend "s3" {
    encrypt = true
    bucket  = "tumi-api-terraform-state"
    region  = "eu-west-1"
    key     = "ecr/terraform.tfstate"
  }
}

terraform {
  required_version = ">= 1.2.2"
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_ecr_repository" "repositories" {
  for_each             = toset(local.ecr_repositories)
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  tags = local.common_tags
}
