resource "aws_sns_topic" "missing_tags_enforcer" {
  name = "untagged-instance-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.missing_tags_enforcer.arn
  protocol  = "email"
  endpoint  = var.alert_email

  # Note: AWS emails var.alert_email a confirmation link after `apply`.
  # The subscription stays PendingConfirmation - and no alerts arrive -
  # until that link is clicked.
}
