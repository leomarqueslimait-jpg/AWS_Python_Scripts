# Zips up the handler scripts so they can be uploaded as Lambda deployment
# packages. boto3 doesn't need to be bundled - it's already in the runtime.
# Scripts live in sibling folders to infra/: lambda_pm/ (stop, evening) and
# lambda_am/ (start, morning).
data "archive_file" "instances_to_stop" {
  type        = "zip"
  source_file = "${path.module}/../handler_pm/instances_to_stop.py"
  output_path = "${path.module}/instances_to_stop.zip"
}

data "archive_file" "instances_to_start" {
  type        = "zip"
  source_file = "${path.module}/../handler_am/instances_to_start.py"
  output_path = "${path.module}/instances_to_start.zip"
}

resource "aws_lambda_function" "instances_to_stop" {
  function_name    = "instances-to-stop"
  filename         = data.archive_file.instances_to_stop.output_path
  source_code_hash = data.archive_file.instances_to_stop.output_base64sha256
  handler          = "instances_to_stop.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 30
}

resource "aws_lambda_function" "instances_to_start" {
  function_name    = "instances-to-start"
  filename         = data.archive_file.instances_to_start.output_path
  source_code_hash = data.archive_file.instances_to_start.output_base64sha256
  handler          = "instances_to_start.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 30
}
