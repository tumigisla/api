resource "aws_api_gateway_stage" "moderately" {
  rest_api_id           = aws_api_gateway_rest_api.api_gw.id
  stage_name            = "moderately"
  deployment_id         = aws_api_gateway_deployment.moderately.id
  cache_cluster_enabled = false
  /* cache_cluster_size    = "0.5" */

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
  depends_on = [
    aws_api_gateway_rest_api.api_gw,
    aws_api_gateway_deployment.moderately
  ]
}

resource "aws_api_gateway_resource" "image" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  parent_id   = aws_api_gateway_rest_api.api_gw.root_resource_id
  path_part   = "image"
  depends_on = [
    aws_api_gateway_rest_api.api_gw
  ]
}

resource "aws_api_gateway_method" "image" {
  rest_api_id      = aws_api_gateway_rest_api.api_gw.id
  resource_id      = aws_api_gateway_resource.image.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
  request_parameters = {
    "method.request.querystring.url" = true
  }
  depends_on = [
    aws_api_gateway_resource.image
  ]
}

resource "aws_api_gateway_method_settings" "image_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  stage_name  = aws_api_gateway_stage.moderately.stage_name
  method_path = "*/*"
  settings {
    logging_level      = "INFO"
    data_trace_enabled = true
    metrics_enabled    = true
    caching_enabled    = false
    /* cache_ttl_in_seconds                       = 300
    unauthorized_cache_control_header_strategy = "FAIL_WITH_403" */
  }
  depends_on = [
    aws_api_gateway_method.image
  ]
}

resource "aws_api_gateway_deployment" "moderately" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
}


resource "aws_api_gateway_integration" "moderately" {
  rest_api_id             = aws_api_gateway_rest_api.api_gw.id
  resource_id             = aws_api_gateway_resource.image.id
  http_method             = aws_api_gateway_method.image.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = data.terraform_remote_state.lambda.outputs.moderately_invoke_arn
  request_parameters = {
    "integration.request.querystring.url" = "method.request.querystring.url"
  }
  depends_on = [
    aws_api_gateway_method.image
  ]
}

resource "aws_api_gateway_usage_plan" "moderately" {
  name = "moderately_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api_gw.id
    stage  = aws_api_gateway_stage.moderately.stage_name
  }
  depends_on = [
    aws_api_gateway_stage.moderately
  ]
}

resource "aws_api_gateway_api_key" "moderately" {
  name = "moderately_api_key"
}

resource "aws_api_gateway_usage_plan_key" "moderately" {
  key_id        = aws_api_gateway_api_key.moderately.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.moderately.id
  depends_on = [
    aws_api_gateway_usage_plan.moderately
  ]
}