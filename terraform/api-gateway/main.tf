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


resource "aws_apigatewayv2_api" "api_gw" {
  name          = "api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "api_gw" {
  api_id = aws_apigatewayv2_api.api_gw.id

  name        = "api"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "moderately" {
  api_id = aws_apigatewayv2_api.api_gw.id

  integration_uri    = data.terraform_remote_state.lambda.outputs.moderately_invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "moderately" {
  api_id = aws_apigatewayv2_api.api_gw.id

  route_key = "GET /moderation_labels"
  target    = "integrations/${aws_apigatewayv2_integration.moderately.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.api_gw.name}"

  retention_in_days = 30
}
