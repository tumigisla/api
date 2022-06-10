locals {
  aws_region = "eu-west-1"
  common_tags = tomap({
    "Owner"         = "DevOps",
    "Business Unit" = "IT",
    "Customer"      = "General",
    "terraform"     = "true",
    "state"         = "api_gateway"
  })
}


terraform {
  backend "s3" {
    encrypt = true
    bucket  = "tumi-api-terraform-state"
    region  = "eu-west-1"
    key     = "api_gateway/terraform.tfstate"
  }
}

terraform {
  required_version = ">= 1.2.2"
}

provider "aws" {
  region = "eu-west-1"
}

data "terraform_remote_state" "lambda" {
  backend = "s3"

  config = {
    bucket = "tumi-api-terraform-state"
    region = "eu-west-1"
    key    = "lambda/terraform.tfstate"
  }
}


resource "aws_api_gateway_rest_api" "api_gw" {
  name           = "api"
  api_key_source = "HEADER"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_api_gateway_rest_api.api_gw.name}"

  retention_in_days = 30
}