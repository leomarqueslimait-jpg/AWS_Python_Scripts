# EC2 Tag Enforcement (Event-Driven)

## Overview

This project enforces tagging at the moment an EC2 instance launches, instead of finding out about it later. A new `RunInstances` API call is logged by CloudTrail, forwarded to EventBridge, and matched by a rule that invokes a Lambda function within seconds of the instance coming up. The Lambda checks the new instance's tags, sends an email alert through SNS if it's missing them, and stops the instance so it can't rack up cost or sit out of compliance while nobody's looking.

It's a companion to my earlier [EC2 dev/prod scheduler](../script2/EC2_SCHEDULER_README.md) project, but a different trigger model entirely. That one polls on a cron. This one reacts to a specific API call the instant it happens — no waiting for the next scheduled check.

## Architecture Diagram

*(to add — planning to include: the EventBridge rule pattern in the console, the CloudTrail trail config, a confirmed SNS email subscription, CloudWatch Logs from a live invocation, and the EC2 console showing an untagged instance getting stopped)*

## Design Decisions

**Event-driven over scheduled.** The scheduler project checks tags whenever it happens to run. This project checks the instant an instance exists, which matters if the whole point is stopping something before it does damage — a scan that runs once a day doesn't help if the instance is untagged and running for 23 hours before anyone notices.

**CloudTrail is a hard requirement, not a nice-to-have.** I assumed I could just write an EventBridge rule matching `RunInstances` and be done with it. That's not true — EventBridge only receives "AWS API Call via CloudTrail" events if a CloudTrail trail actually exists and is delivering to S3. Without the trail, the rule sits there matching nothing, silently. That meant adding a trail and an S3 bucket to this stack that otherwise has nothing to do with logging.

**The S3 bucket policy needed the modern, ACL-free version.** Most CloudTrail bucket policy examples I found online still condition the `PutObject` permission on an `s3:x-amz-acl` header. That's leftover from before S3 changed its default object ownership to `BucketOwnerEnforced`, which disables ACLs entirely. If I'd copied the older policy, CloudTrail's log deliveries would have failed the IAM condition on every single write, since it doesn't send that header anymore. The fix was dropping the ACL condition and keeping only the `aws:SourceArn` check.

**Two IAM roles, not one.** The scheduler Lambdas' role only needs `Stop`/`Start` scoped to instances tagged `Schedule=office-hours`. This Lambda needs `Stop` scoped the opposite way — to instances that *don't* have an `Environment` tag at all — plus `sns:Publish`, which the scheduler functions have no reason to hold. Rather than widen one shared role, I gave this Lambda its own, so each role only grants exactly what its own function does.

**The Stop permission is scoped by absence, not presence.** The IAM condition uses `Null: aws:ResourceTag/Environment = true`, which matches only instances missing that tag key. That makes the permission structurally incapable of touching my existing tagged prod or dev instances — there's no code path where it could reach them, because the condition itself excludes anything already tagged.

**Instance IDs come from `responseElements`, not `requestParameters`.** The CloudTrail event's `requestParameters` shows what tags were *requested* at launch time, which isn't the same as what's actually on the instance. I pull instance IDs from `responseElements` instead, then call `describe_instances` for the real, current state — same check the standalone `ec2_missing_tags.py` script already does.

**The handler loops over a list, even for one instance.** `RunInstances` can create several instances in a single call, so `responseElements.instancesSet.items` is always a list. My own Terraform launches produce one instance per API call (Terraform issues a separate `RunInstances` call per resource, even under `count`), so in practice I'll almost always see a single-item list — but the code can't assume that, since anyone launching from the console or CLI with a count could trigger a multi-item event.

## Biggest Challenge

The CloudTrail requirement was the part that actually stopped me. I had the event pattern written and correct, deployed it, launched a test instance, and nothing happened — no logs, no errors, just silence. It took real digging to find out that "AWS API Call via CloudTrail" events aren't just a label; EventBridge genuinely won't receive them without a trail actively delivering to S3. It's not something the EventBridge console or the rule itself tells you is missing. Once I added the trail and got the bucket policy right (including the ACL condition mismatch above), the same rule I'd already written started firing exactly as expected — the rule was never the problem, the missing prerequisite was.

## Intended Audience

This project is meant to show that I can design for governance, not just deployment — catching a compliance gap (missing tags) at the moment it happens instead of after the fact. It's aimed at roles like Cloud Engineer, DevOps Engineer, or Cloud Security Engineer, where being able to reason about event-driven AWS architecture, least-privilege IAM conditions, and the less obvious dependencies between services (like CloudTrail-to-EventBridge) matters as much as knowing the Terraform syntax to provision any of it.

## Prerequisites

| Requirement | Notes |
|---|---|
| AWS CLI configured | Credentials with permission to create CloudTrail, S3, EventBridge, SNS, IAM, and Lambda resources |
| Terraform >= 1.5.0 | |
| Python 3.12 | Matches the Lambda runtime, needed if testing the script locally |
| Access to the inbox for `alert_email` | Required to confirm the SNS subscription after apply |

## Deployment

### 1. Clone the repo
```bash
git clone git@github.com:leomarqueslimait-jpg/AWS_Python_Scripts.git
cd AWS_Python_Scripts/ec2_scripts/script3/infra
```

### 2. Set your alert email
```bash
echo 'alert_email = "you@example.com"' > terraform.tfvars
```

### 3. Initialize and apply
```bash
terraform init
terraform plan
terraform apply
```

### 4. Confirm the SNS subscription
AWS emails `alert_email` a confirmation link right after apply. No alerts arrive until it's clicked.

### 5. Test it
Launch an EC2 instance without an `Environment` tag and watch CloudWatch Logs for the Lambda's invocation, the SNS email arrive, and the instance stop.

## Cost Estimate

| Service | Monthly Cost |
|---|---|
| CloudTrail (management events, 1 trail) | $0.00 (first trail's management events are free) |
| S3 (CloudTrail logs, < 1 GB) | ~$0.02 |
| EventBridge (rule matches) | ~$0.00 |
| Lambda (well under 1M invocations) | $0.00 (free tier) |
| SNS (email, low volume) | $0.00 (free tier covers first 1,000/month) |
| **Total** | **< $1/month** |

Estimate assumes personal/portfolio-scale traffic, not production launch volume.

## Destroy

```bash
terraform destroy
```

The S3 bucket has `force_destroy = true` set, so leftover CloudTrail log objects won't block the destroy the way they would on a default bucket.
