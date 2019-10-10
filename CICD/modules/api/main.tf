data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.application}-${var.env}-${var.color}-cicd-api-${data.aws_region.current.name}"
}

resource "aws_api_gateway_resource" "api" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part   = "cicd"
}

resource "aws_api_gateway_method" "api" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.api.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api" {
  rest_api_id               = "${aws_api_gateway_rest_api.api.id}"
  resource_id               = "${aws_api_gateway_resource.api.id}"
  http_method               = "${aws_api_gateway_method.api.http_method}"
  integration_http_method   = "POST"
  type                      = "AWS"
  timeout_milliseconds      = 10000
  uri                       = "${var.lambda_invoke_arn}"
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowExecution"
  action        = "lambda:InvokeFunction"
  function_name = "${var.lambda_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.api.http_method}${aws_api_gateway_resource.api.path}"
}