# Different trigger mechanism than script2's aws_scheduler_schedule: this
# fires on a matched API call, not a timer, so it's the classic
# aws_cloudwatch_event_rule + resource-based Lambda permission, not
# EventBridge Scheduler's assumed-role invocation.

resource "aws_cloudwatch_event_rule" "run_instances" {
  name        = "tag-enforcement-run-instances"
  description = "Matches EC2 RunInstances API calls, sourced from CloudTrail"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["RunInstances"]
    }
  })

  depends_on = [aws_cloudtrail.this]
}

resource "aws_cloudwatch_event_target" "tag_enforcement" {
  rule = aws_cloudwatch_event_rule.run_instances.name
  arn  = aws_lambda_function.ec2_missing_tags_enforcer.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_missing_tags_enforcer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.run_instances.arn
}
