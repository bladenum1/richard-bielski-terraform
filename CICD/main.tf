data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "lambda" {
    source = "./modules/lambda"
    application = "${var.application}"
    env = "${var.env}"
    color = "${var.color}"
    created_by = "${var.created_by}"
    domain = "${var.domain}"
    dns_zone_id = "${var.dns_zone_id}"
    viewer_certificate = "${var.viewer_certificate}"
    comment = "${var.comment}"
    region = "${var.region}"
    profile = "${var.profile}"

}

module "api" {
    source = "./modules/api"
    application = "${var.application}"
    env = "${var.env}"
    color = "${var.color}"
    created_by = "${var.created_by}"
    domain = "${var.domain}"
    dns_zone_id = "${var.dns_zone_id}"
    viewer_certificate = "${var.viewer_certificate}"
    comment = "${var.comment}"
    region = "${var.region}"
    profile = "${var.profile}"
    lambda_invoke_arn = "${module.lambda.lambda_invoke_arn}"
    lambda_name = "${module.lambda.lambda_name}"
}