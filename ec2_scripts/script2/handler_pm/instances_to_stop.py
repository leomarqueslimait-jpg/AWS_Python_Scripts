# Finds every EC2 instance tagged for this schedule that's currently
# "running" and stops them in a single batched API call.

import boto3
from botocore.exceptions import ClientError

# created once per Lambda cold start and reused across warm invocations
ec2 = boto3.client('ec2')


def get_running_instance_ids():
    # Get all currently running instances that are also tagged for this
    # schedule, so only intended instances get stopped (not the whole account)
    running_instances = ec2.describe_instances(Filters=[
        {
            "Name": "instance-state-name",
            "Values": ["running"]
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
    for reservation in running_instances["Reservations"]:
        for instance in reservation["Instances"]:
            # collect the id so it can be passed to stop_instances() as a batch
            ids.append(instance["InstanceId"])
    return ids


def stop_instances(instance_ids):
    try:
        # stop_instances requires InstanceIds as a list, even for one id
        ec2.stop_instances(InstanceIds=instance_ids)
        print(f"Stopping instances {instance_ids} ...")
    except ClientError as e:
        # raised when InstanceIds is empty, i.e. nothing is running
        if e.response["Error"]["Code"] == "InvalidParameterCombination":
            print("No instances in a 'running' state")


def main():
    instance_ids = get_running_instance_ids()
    stop_instances(instance_ids)


def lambda_handler(event, context):
    # AWS Lambda's entrypoint (set in Terraform as
    # "instances_to_stop.lambda_handler"). Runs fresh on every invocation,
    # unlike module-level code, which only runs once per cold start and
    # would otherwise leak stale instance ids across warm invocations.
    main()


if __name__ == "__main__":
    # only runs when this file is executed directly (e.g. local testing),
    # not when AWS Lambda imports it and calls lambda_handler
    main()