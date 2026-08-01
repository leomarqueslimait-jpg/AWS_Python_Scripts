# EventBridge cron expressions are always UTC - adjust the hours below
# for your timezone offset before applying.
resource "aws_cloudwatch_event_rule" "stop_schedule" {
  name                = "stop-dev-instances"
  description         = "Stops tagged dev instances every weekday evening"
  schedule_expression = "cron(0 19 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_rule" "start_schedule" {
  name                = "start-dev-instances"
  description         = "Starts tagged dev instances every weekday morning"
  schedule_expression = "cron(0 7 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "stop_target" {
  rule = aws_cloudwatch_event_rule.stop_schedule.name
  arn  = aws_lambda_function.instances_to_stop.arn
}

resource "aws_cloudwatch_event_target" "start_target" {
  rule = aws_cloudwatch_event_rule.start_schedule.name
  arn  = aws_lambda_function.instances_to_start.arn
}

# Without these, EventBridge is not allowed to invoke the Lambdas -
# the rule would fire but the function would never actually run.
resource "aws_lambda_permission" "allow_stop_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridgeStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.instances_to_stop.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_schedule.arn
}

resource "aws_lambda_permission" "allow_start_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.instances_to_start.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_schedule.arn
}
