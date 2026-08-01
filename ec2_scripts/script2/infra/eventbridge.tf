# Uses EventBridge Scheduler (aws_scheduler_schedule), not the classic
# aws_cloudwatch_event_rule. Scheduler supports schedule_expression_timezone,
# so cron is written in local time and AWS handles the UTC conversion and
# daylight saving shift automatically - a plain UTC cron on the classic
# rules resource would silently drift an hour off twice a year.
resource "aws_scheduler_schedule" "stop_schedule" {
  name = "stop-dev-instances"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(0 19 ? * MON-FRI *)"
  schedule_expression_timezone = "America/Chicago"

  target {
    arn      = aws_lambda_function.instances_to_stop.arn
    role_arn = aws_iam_role.scheduler_invoke.arn
  }
}

resource "aws_scheduler_schedule" "start_schedule" {
  name = "start-dev-instances"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(0 7 ? * MON-FRI *)"
  schedule_expression_timezone = "America/Chicago"

  target {
    arn      = aws_lambda_function.instances_to_start.arn
    role_arn = aws_iam_role.scheduler_invoke.arn
  }
}