# Scans all non-terminated EC2 instances in the account/region and
# records which tags each one has (or flags it as untagged).
# Results are printed to console and saved to ec2_tags.json.

import boto3
from botocore.exceptions import ClientError
import json

ec2 = boto3.client('ec2')

# Get all EC2 instances that are not terminated (skips instances AWS
# still shows but that no longer really "exist" for tagging purposes)
response = ec2.describe_instances(Filters=[
    {
        "Name": "instance-state-name",
        "Values": ["pending", "running", "stopping", "stopped"]
    }
])

# Will hold one sublist per instance: [instance_id, {tag}, {tag}, ...]
outter_list = []

def check_tags():
    i = 0  # tracks the index of the current instance's sublist in outter_list
    for reservation in response["Reservations"]:
        for instances in reservation['Instances']:
            instance_id = instances["InstanceId"]

            # start this instance's entry with just its ID
            outter_list.append([instance_id])

            try:
                # instances['Tags'] only exists if the instance has tags;
                # missing key raises KeyError, caught below
                for tags in instances['Tags']:

                    key = tags["Key"]
                    value = tags["Value"]
                    outter_list[i].append({"key": key, "value": value})

            except KeyError as e:
                # no 'Tags' key on this instance = untagged instance
                outter_list[i].append("There are no tags")

            i += 1  # move to next instance's index for the next iteration
check_tags()

def to_json():
    # write the collected data out as a JSON file for later review
    with open("ec2_tags.json", "w") as file:
        json.dump(outter_list, file, indent=4, sort_keys=True)

to_json()

print(outter_list)