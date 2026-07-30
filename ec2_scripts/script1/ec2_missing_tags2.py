import boto3
from botocore.exceptions import ClientError   
import json

ec2 = boto3.client('ec2')
response = ec2.describe_instances(Filters=[
    {
        "Name": "instance-state-name",
        "Values": ["pending", "running", "stopping", "stopped"]

    }
])

outter_list = []

def check_tags():
    i = 0
    for reservation in response["Reservations"]:
        for instances in reservation['Instances']:
            instance_id = instances["InstanceId"]
            
            outter_list.append([instance_id])
                
            try:
                for tags in instances['Tags']:
                    
                    key = tags["Key"]
                    value = tags["Value"]
                    outter_list[i].append({"key": key, "value" : value})

            except KeyError as e:
                outter_list[i].append("There are no tags")

            i += 1
check_tags()        

def to_json():
    with open("ec2_tags.json", "w") as file:
        json.dump(outter_list, file, indent=4, sort_keys=True)

to_json()
        
print(outter_list)