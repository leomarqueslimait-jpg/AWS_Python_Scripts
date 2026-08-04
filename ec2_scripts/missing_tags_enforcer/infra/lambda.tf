locals {
  function_name = "ec2_missing_tags_enforcer"
}

data "archive_file" "missing_tags_enforcer" {
  type        = "zip"
  source_file = "${path.module}/../handler/ec2_missing_tags.py"
  output_path = "${path.module}/ec2_missing_tags_enforcer.zip"
}

resource "aws_lambda_function" "ec2_missing_tags_enforcer" {
  function_name    = local.function_name
  filename         = data.archive_file.missing_tags_enforcer.output_path
  source_code_hash = data.archive_file.missing_tags_enforcer.output_base64sha256
  handler          = "ec2_missing_tags.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.ec2_missing_tags_enforcer.arn
  timeout          = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.missing_tags_enforcer.arn
    }
  }
}
