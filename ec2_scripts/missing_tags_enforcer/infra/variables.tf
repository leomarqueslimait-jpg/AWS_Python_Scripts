variable "aws_region" {
  description = "Region"
  type        = string
}

variable "alert_email" {
  description = "Email address that receives the untagged-instance SNS notification"
  type        = string
  # No default on purpose - keep it out of version control.
  # Set it in a terraform.tfvars file (already gitignored) or via TF_VAR_alert_email.
}
