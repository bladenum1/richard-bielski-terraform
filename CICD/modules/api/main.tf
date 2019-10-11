data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.application}-${var.env}-${var.color}-cicd-api-${data.aws_region.current.name}"
}

resource "aws_api_gateway_method" "api" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "api" {
  rest_api_id               = "${aws_api_gateway_rest_api.api.id}"
  resource_id               = "${aws_api_gateway_rest_api.api.root_resource_id}"
  http_method               = "${aws_api_gateway_method.api.http_method}"
  integration_http_method   = "POST"
  type                      = "AWS"
  timeout_milliseconds      = 10000
  uri                       = "${var.lambda_invoke_arn}"
}

resource "aws_api_gateway_method_response" "api" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_rest_api.api.root_resource_id}"
  http_method = "${aws_api_gateway_method.api.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "api" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_rest_api.api.root_resource_id}"
  http_method = "${aws_api_gateway_method.api.http_method}"
  status_code = "${aws_api_gateway_method_response.api.status_code}"
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowExecution"
  action        = "lambda:InvokeFunction"
  function_name = "${var.lambda_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.api.http_method}/"
}

resource "aws_api_gateway_deployment" "api" {
  depends_on = [
    "aws_api_gateway_integration.api",
    "aws_api_gateway_integration_response.api",
  ] 
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "prod"
}

# THIS BLOCK OF CODE WILL CONFIGURE AN API KEY, BUT GITHUB WEBHOOKS DON'T SUPPORT IT CURRENTLY :(
# Secret's used instead, unfortunately this will not prevent lambda costs for the invocations...
# resource "aws_api_gateway_usage_plan" "api" {
#   name = "${var.application}-${var.env}-${var.color}-cicd-api-${data.aws_region.current.name}"

#   api_stages {
#     api_id = "${aws_api_gateway_rest_api.api.id}"
#     stage  = "${aws_api_gateway_deployment.api.stage_name}"
#   }
# }

# resource "aws_api_gateway_api_key" "api" {
#   name = "${var.application}-${var.env}-${var.color}-cicd-api-${data.aws_region.current.name}"
# }

# resource "aws_api_gateway_usage_plan_key" "api" {
#   key_id        = "${aws_api_gateway_api_key.api.id}"
#   key_type      = "API_KEY"
#   usage_plan_id = "${aws_api_gateway_usage_plan.api.id}"
# }