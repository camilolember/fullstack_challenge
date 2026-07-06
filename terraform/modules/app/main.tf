# s3 bucket for app
resource "aws_s3_bucket" "clemus-bucket-app" {
  bucket = "clemus-bucket-app-#{var.environment}"

  tags = {
    Name = "App bucket"
  }
}

# s3 bucket for logging
resource "aws_s3_bucket" "clemus-bucket-logging" {
  bucket = "clemus-bucket-logging-#{var.environment}"

  tags = {
    Name = "Loggin bucket"
  }
}

# cloudfront dist

# See https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html
data "aws_iam_policy_document" "origin_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.b.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bp" {
  bucket = aws_s3_bucket.clemus-bucket-app.bucket
  policy = data.aws_iam_policy_document.origin_bucket_policy.json
}

locals {
  s3_origin_id = "myS3Origin"
  my_domain    = "mydomain.com"
}

#data "aws_acm_certificate" "my_domain" {
#  region   = "us-east-1"
#  domain   = "*.${local.my_domain}"
#  statuses = ["ISSUED"]
#}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "default-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.clemus-bucket-app.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  aliases = ["mysite.${local.my_domain}", "yoursite.${local.my_domain}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  #ordered_cache_behavior {
  #  path_pattern     = "/content/immutable/*"
  #  allowed_methods  = ["GET", "HEAD", "OPTIONS"]
  #  cached_methods   = ["GET", "HEAD", "OPTIONS"]
  #  target_origin_id = local.s3_origin_id

  #  forwarded_values {
  #    query_string = false
  #    headers      = ["Origin"]

  #    cookies {
  #      forward = "none"
  #    }
  #  }

  #  min_ttl                = 0
  #  default_ttl            = 86400
  #  max_ttl                = 31536000
  #  compress               = true
  #  viewer_protocol_policy = "redirect-to-https"
  #}

  # Cache behavior with precedence 1
  #ordered_cache_behavior {
  #  path_pattern     = "/content/*"
  #  allowed_methods  = ["GET", "HEAD", "OPTIONS"]
  #  cached_methods   = ["GET", "HEAD"]
  #  target_origin_id = local.s3_origin_id

  #  forwarded_values {
  #    query_string = false

  #    cookies {
  #      forward = "none"
  #    }
  #  }

  #  min_ttl                = 0
  #  default_ttl            = 3600
  #  max_ttl                = 86400
  #  compress               = true
  #  viewer_protocol_policy = "redirect-to-https"
  #}

  #price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      #locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  #viewer_certificate {
  #  acm_certificate_arn = data.aws_acm_certificate.my_domain.arn
  #  ssl_support_method  = "sni-only"
  #}
}