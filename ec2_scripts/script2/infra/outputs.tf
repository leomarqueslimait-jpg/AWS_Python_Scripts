output "prod_instance_ids" {
  value = aws_instance.prod[*].id
}

output "dev_instance_ids" {
  value = aws_instance.dev[*].id
}

output "stop_lambda_name" {
  value = aws_lambda_function.instances_to_stop.function_name
}

output "start_lambda_name" {
  value = aws_lambda_function.instances_to_start.function_name
}
