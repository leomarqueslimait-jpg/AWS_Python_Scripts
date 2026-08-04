resource "aws_cloudtrail" "this" {
  depends_on             = [aws_s3_bucket_policy.missing_tags_enforcer]
  name                   = "missing_tags_enforcer"
  s3_bucket_name         = aws_s3_bucket.missing_tags_enforcer.id
  is_multi_region_trail  = false

  event_selector {
    # only log write-type management events (skips Describe/List/ etc...)
    read_write_type            = "WriteOnly"
    include_management_events  = true
  }

  enable_logging = true
}

resource "aws_s3_bucket" "missing_tags_enforcer" {
  bucket        = "trail-missing-tags-enforcer"
  force_destroy = true
}

data "aws_iam_policy_document" "missing_tags_enforcer" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.missing_tags_enforcer.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/missing_tags_enforcer"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.missing_tags_enforcer.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/missing_tags_enforcer"]
    }
  }
}

resource "aws_s3_bucket_policy" "missing_tags_enforcer" {
  bucket = aws_s3_bucket.missing_tags_enforcer.id
  policy = data.aws_iam_policy_document.missing_tags_enforcer.json
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
