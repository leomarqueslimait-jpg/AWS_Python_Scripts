# Finds every EC2 instance tagged for this schedule that's currently
# "stopped" and starts them in a single batched API call.

import boto3
from botocore.exceptions import ClientError

# created once per Lambda cold start and reused across warm invocations
ec2 = boto3.client('ec2')


def get_stopped_instance_ids():
    # Get all currently stopped instances that are also tagged for this
    # schedule, so only intended instances get started (not the whole account)
    stopped_instances = ec2.describe_instances(Filters=[
        {
            "Name": "instance-state-name",
            "Values": ["stopped"]
        },
        {
            "Name": "tag:Environment",
            "Values": ["dev"]
        },
        {
            "Name": "tag:Schedule",
            "Values": ["office-hours"]
        }
    ])

    # response is nested: Reservations -> Instances -> instance dict
    ids = []
    for reservation in stopped_instances["Reservations"]:
        for instance in reservation["Instances"]:
            # collect the id so it can be passed to start_instances() as a batch
            ids.append(instance["InstanceId"])
    return ids


def start_instances(instance_ids):
    try:
        # start_instances requires InstanceIds as a list, even for one id
        ec2.start_instances(InstanceIds=instance_ids)
        print(f"Starting instances {instance_ids} ...")
    except ClientError as e:
        # raised when InstanceIds is empty, i.e. nothing is stopped
        if e.response["Error"]["Code"] == "InvalidParameterCombination":
            print("No instances in a 'stopped' state")


def main():
    instance_ids = get_stopped_instance_ids()
    start_instances(instance_ids)


def lambda_handler(event, context):
    # AWS Lambda's entrypoint (set in Terraform as
    # "instances_to_start.lambda_handler"). Runs fresh on every invocation,
    # unlike module-level code, which only runs once per cold start and
    # would otherwise leak stale instance ids across warm invocations.
    main()


if __name__ == "__main__":
    # only runs when this file is executed directly (e.g. local testing),
    # not when AWS Lambda imports it and calls lambda_handler
    main()