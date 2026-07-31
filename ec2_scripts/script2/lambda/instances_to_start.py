# Finds every EC2 instance currently in the "stopped" state and stops
# them in a single batched API call
import boto3
from botocore.exceptions import ClientError


ec2 = boto3.client('ec2')

# Get all currently running instances that are also tagged for this
# schedule, so only intended instances get stopped 
stopped_instances = ec2.describe_instances(Filters=[
    {
        "Name": "instance-state-name",
        "Values": ["stopped"]
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
# Will hold the instance IDs of every stopped instance found with those tags
stopped_instances_ids = []

def add_stopped_instance_to_list():
     # response is nested: Reservations -> Instances -> instance dict
    for reservation in stopped_instances["Reservations"]:
        for instances in reservation['Instances']:
            
            #store the instance id in a variable 
            instance_id = instances["InstanceId"]

            # collect the id so it can be passed to stop_instances() as a batch
            stopped_instances_ids.append(instance_id)
        

def start_instances():
    try:
        # start_instances requires InstanceIds as a list, even for one id
        ec2.start_instances(InstanceIds=stopped_instances_ids) 
        print(f"Starting instances {stopped_instances_ids} ...")    
    except ClientError as e:
        # raised when InstanceIds is empty, i.e. nothing is running
        if e.response["Error"]["Code"] == "InvalidParameterCombination":
            print("No instances in a 'stopped' state")


def main():
    add_stopped_instance_to_list()
    start_instances()

# only runs when this file is executed directly (e.g. local testing),
# not when AWS Lambda imports it and calls a handler
if __name__ == "__main__":
    main()
print()

