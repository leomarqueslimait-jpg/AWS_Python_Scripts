# Finds every EC2 instance currently in the "running" state and stops
# them in a single batched API call
import boto3
import boto3
from botocore.exceptions import ClientError

ec2 = boto3.client('ec2')

running_instances = ec2.describe_instances(Filters=[
    {
        "Name": "instance-state-name",
        "Values": ["running"]
    },
    {
        "Name": "tag:Environment",
        "Values": ['dev']
        },
    {
        "Name": "tag:Schedule",
        "Values": ["office-hours"]
        }
    
    ])
    

# Will hold the instance IDs of every running instance found with those tags

running_instances_ids = []

def add_running_instance_to_list():

    # loops through the list of lists until the dict 'Tags' 
    for reservation in running_instances["Reservations"]:
        for instances in reservation['Instances']:
            # store the instance id in a variable 
            instance_id = instances["InstanceId"]
    
             # collect the id so it can be passed to stop_instances() as a batch
            running_instances_ids.append(instance_id)
        

def stop_instances():
    try:
        # stop_instances requires InstanceIds as a list, even for one id
        ec2.stop_instances(InstanceIds=running_instances_ids) 
        print(f"Stopping instances {running_instances_ids} ...")    
    except ClientError as e:
        # raised when InstanceIds is empty, i.e. nothing is running
        if e.response["Error"]["Code"] == "InvalidParameterCombination":
            print("No instances in a 'running' state")


def main():
    add_running_instance_to_list()
    stop_instances()

# only runs when this file is executed directly (e.g. local testing),
# not when AWS Lambda imports it and calls a handler
if __name__ == "__main__":
    main()

