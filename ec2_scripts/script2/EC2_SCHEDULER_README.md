# EC2 Environment Scheduler

## Overview

This project provisions a small AWS environment — a VPC with separate subnets for prod and dev, three EC2 instances tagged `Environment=prod` and three tagged `Environment=dev` — and then automatically stops and starts the dev instances on a weekday schedule using Lambda and EventBridge Scheduler. Prod instances are never touched. The point is to stop paying for dev/test compute that nobody's using overnight, without needing to remember to do it manually.

## Architecture Diagram

*(Add a screenshot or diagram here — EventBridge Scheduler on a cron trigger, two Lambda functions, targeting tagged EC2 instances inside the VPC.)*

## Design Decisions

### Tagging strategy
I separated environment (`Environment=dev`/`prod`) from scheduling intent (`Schedule=office-hours`) as two independent tags, instead of filtering on environment alone. This lets an instance opt out of the schedule without needing an exception list, and guarantees the scheduler Lambdas can never touch a prod instance, since prod is never tagged with `Schedule` at all.

### IAM scoping
The Lambda's IAM policy is scoped down with a resource tag condition (`aws:ResourceTag/Schedule = office-hours`) on `ec2:StopInstances`/`StartInstances`, so the permission itself — not just the application logic — is limited to the intended instances.

### Lambda execution model
The scheduler Lambdas build their instance list inside the handler function rather than at the top of the file. Lambda reuses warm execution environments across invocations, so any code outside a function only runs once per cold start — module-level state would have leaked stale instance IDs across scheduled runs instead of returning a fresh list every time.

### Scheduling
EventBridge Scheduler (`aws_scheduler_schedule`) handles the cron trigger instead of the classic `aws_cloudwatch_event_rule`. It supports a `schedule_expression_timezone` field, so the cron is written directly in Central time rather than manually converted to UTC — which also means the schedule doesn't drift when daylight saving shifts the UTC offset twice a year. Because Scheduler authorizes through an assumed IAM role rather than a resource-based Lambda permission, it required its own dedicated role, separate from the Lambda execution role.

## Intended Audience

This project is meant to demonstrate cost-optimization automation and tag-based governance — the kind of practical, recurring problem a Cloud Engineer or DevOps Engineer runs into on a real team, where dev/staging resources end up running around the clock for no reason. It's aimed at roles where being comfortable gluing together Lambda, EventBridge, and IAM to solve an operational problem matters as much as being able to provision the infrastructure in the first place.

## Prerequisites

| Requirement | Notes |
|---|---|
| Terraform >= 1.5 | |
| AWS CLI configured | credentials need permission to create VPC, EC2, Lambda, IAM, and EventBridge Scheduler resources |
| Python 3 | only needed if you want to test the Lambda scripts locally before deploying |

## Deployment

### 1. Clone the repo
```bash
git clone git@github.com:leomarqueslimait-jpg/AWS_Python_Scripts.git
cd AWS_Python_Scripts/ec2_scripts/script2/infra
```

### 2. Review the variables
Check `variables.tf` — in particular, tighten `ssh_ingress_cidr` to your own IP before applying, and adjust `schedule_expression_timezone` in `eventbridge.tf` if you're not in Central time.

### 3. Initialize and apply
```bash
terraform init
terraform plan
terraform apply
```

### 4. Note the outputs
After apply, Terraform prints the prod/dev instance IDs and both Lambda function names.

## Cost Estimate

| Service | Monthly Cost |
|---|---|
| EC2 — prod (3x t3.micro, running 24/7) | ~$23 |
| EC2 — dev (3x t3.micro, ~50 hrs/week via scheduler) | ~$7 |
| EBS (6x 8GB gp3 root volumes) | ~$4 |
| Lambda (2 functions, a few invocations/day) | $0.00 (free tier) |
| EventBridge Scheduler | $0.00 |
| **Total** | **~$34/month** |

This assumes usage beyond the AWS free tier, since six always-on/scheduled instances exceed the single-instance free tier allowance. Destroy the environment when you're not actively using it.

## Destroy

```bash
terraform destroy
```

This project is meant to be spun up and torn down, not left running indefinitely — remember to destroy it once you're done testing.
