data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
    comment = "${var.comment}"
}

data "aws_route53_zone" "zone" {
    zone_id = "${var.dns_zone_id}"
    private_zone = false
}

resource "aws_route53_record" "record" {
    zone_id = "${var.dns_zone_id}"
    name = "${data.aws_route53_zone.zone.name}"
    type = "A"
    allow_overwrite = true

    alias {
        name = "${aws_cloudfront_distribution.cdn.domain_name}"
        zone_id = "Z2FDTNDATAQYW2"
        evaluate_target_health = false
    }
}

resource "aws_cloudfront_distribution" "cdn" {
    origin {
        domain_name = "${aws_s3_bucket.bucket.bucket_regional_domain_name}"
        origin_id   = "${aws_s3_bucket.bucket.bucket}"

        s3_origin_config {
            origin_access_identity = "origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.origin_access_identity.id}"
        }
    }

    aliases             = ["${var.domain}"]
    enabled             = true
    is_ipv6_enabled     = true
    comment             = "${var.comment}"
    default_root_object = "index.html"

    default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.bucket.bucket}"
        
        forwarded_values {
            query_string = false
            headers = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
            cookies {
            forward = "none"
        }
    }

    viewer_protocol_policy = "allow-all"
        min_ttl                = 0
        default_ttl            = 2400
        max_ttl                = 8600
    }
    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    viewer_certificate {
        acm_certificate_arn =  "${var.viewer_certificate}"
        ssl_support_method = "sni-only"
    }
}

resource "aws_s3_bucket" "bucket" {
    bucket = "${var.application}-${var.env}-${var.color}-${data.aws_region.current.name}"
    force_destroy = true
    tags = {
        Name = "${var.application}-${var.env}-${var.color}-${data.aws_region.current.name}"
        Environment = "${var.env}"
        DeployColor = "${var.color}"
        Function = "s3"
    }
    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
    versioning {
        enabled = false
    }
}

data "aws_iam_policy_document" "s3_policy" {
    statement {
        actions   = ["s3:GetObject"]
        resources = ["${aws_s3_bucket.bucket.arn}/*"]

        principals {
            type        = "CanonicalUser"
            identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.s3_canonical_user_id}"]
        }
    }

    statement {
        actions   = ["s3:ListBucket"]
        resources = ["${aws_s3_bucket.bucket.arn}"]

        principals {
            type        = "CanonicalUser"
            identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.s3_canonical_user_id}"]
        }
    }
}
resource "aws_s3_bucket_policy" "bucket_policy" {
    bucket = "${aws_s3_bucket.bucket.bucket}"
    policy = "${data.aws_iam_policy_document.s3_policy.json}"
}