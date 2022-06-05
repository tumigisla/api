locals {
  aws_region = "eu-west-1"
  image_tag="b2c3cc8c15633caea0f01911b5b0033cf4c67513"
  common_tags = tomap({
    "Owner"         = "DevOps",
    "Business Unit" = "IT",
    "Customer"      = "General",
    "terraform"     = "true",
    "state"         = "ecr"
  })
}


terraform {
  backend "s3" {
    encrypt = true
    bucket  = "tumi-api-terraform-state"
    region  = "eu-west-1"
    key     = "lambda/terraform.tfstate"
  }
}

terraform {
  required_version = ">= 1.2.2"
}

provider "aws" {
  region = "eu-west-1"
}

data "terraform_remote_state" "ecr" {
  backend = "s3"

  config = {
    bucket = "tumi-api-terraform-state"
    region = "eu-west-1"
    key    = "ecr/terraform.tfstate"
  }
}

resource "aws_lambda_function" "moderately" {
    function_name = "moderately"
    role=aws_iam_role.lambda_iam_role.arn
    package_type = "Image"
    image_uri ="${data.terraform_remote_state.ecr.outputs.api_repository_url}:moderately-${local.image_tag}"
    memory_size=128
    timeout = 10
}