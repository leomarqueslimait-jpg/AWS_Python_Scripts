data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "ec2-scheduler-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Scoped down with a tag condition so this role can only stop/start
# instances tagged for this schedule, not every instance in the account
data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"] # DescribeInstances does not support resource-level permissions
  }

  statement {
    actions   = ["ec2:StopInstances", "ec2:StartInstances"]
    resources = ["arn:aws:ec2:*:*:instance/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Schedule"
      values   = ["office-hours"]
    }
  }

  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name   = "ec2-scheduler-lambda-permissions"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}
