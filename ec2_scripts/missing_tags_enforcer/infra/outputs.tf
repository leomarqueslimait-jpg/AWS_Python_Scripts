output "tag_enforcement_function_name" {
  value = aws_lambda_function.ec2_missing_tags_enforcer.function_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.missing_tags_enforcer.arn
}

output "cloudtrail_bucket" {
  value = aws_s3_bucket.missing_tags_enforcer.id
}
