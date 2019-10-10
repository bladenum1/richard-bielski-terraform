data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "lambda_policy" {
    statement {
        sid         = "AllowEverything"
        effect      = "Allow"
        actions     = ["*"]
        resources   = ["*"]
    }
    statement {
        sid         = "AllowLogging"
        effect      = "Allow"
        actions     = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ]   
        resources   = [
            "arn:aws:logs:*:*:*"
        ]
    }
}

resource "aws_iam_policy" "lambda" {
    name    = "${var.application}-${var.env}-${var.color}-cicd-lambda-${data.aws_region.current.name}"
    policy  = "${data.aws_iam_policy_document.lambda_policy.json}"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.application}-${var.env}-${var.color}-cicd-lambda-${data.aws_region.current.name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda_role" {
    statement {
        sid         = "AllowAssumeRole"
        effect      = "Allow"
        actions     = ["sts:AssumeRole"]
        principals  {
                type        = "Service"
                identifiers = ["lambda.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "lambda" {
  name                  = "${var.application}-${var.env}-${var.color}-cicd-lambda-${data.aws_region.current.name}"
  assume_role_policy    = "${data.aws_iam_policy_document.lambda_role.json}"
  depends_on            = ["aws_cloudwatch_log_group.lambda"]
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = "${aws_iam_role.lambda.name}"
  policy_arn = "${aws_iam_policy.lambda.arn}"
}

resource "aws_lambda_function" "lambda" {
    function_name     = "${var.application}-${var.env}-${var.color}-cicd-lambda-${data.aws_region.current.name}"
    handler           = "main"
    role              = "${aws_iam_role.lambda.arn}"
    filename          = "./modules/lambda/main.zip"
    source_code_hash  = "${filebase64sha256("./modules/lambda/main.zip")}"
    runtime           = "go1.x"
    depends_on        = ["aws_cloudwatch_log_group.lambda"]

}