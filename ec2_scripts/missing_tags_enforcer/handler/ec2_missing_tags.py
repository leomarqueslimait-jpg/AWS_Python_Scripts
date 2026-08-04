# Scans all non-terminated EC2 instances in the account/region and
# records which tags each one has (or flags it as untagged).
# Results are printed to console and saved to ec2_tags.json.

import boto3


ec2 = boto3.client('ec2')
   
def check_tags(ids):
    instances_no_tags = []
    response = ec2.describe_instances(InstanceIds=ids)


    # loops through the list of lists until the dict 'Tags' 
    for reservation in response["Reservations"]:
        for instance in reservation['Instances']:
            
            try:          
                instance['Tags']
                continue                                     

            except KeyError as e:
                instances_no_tags.append(instance["InstanceId"])
                # no 'Tags' key on this instance = untagged instance
                


    return instances_no_tags



def get_new_instance_ids(event):
    instance_id_list = []
    #payload from Eventbridge for ec2
    items = event["detail"]["responseElements"]["instancesSet"]["items"]
    for item in items:
        instance_id = item["instanceId"]
        instance_id_list.append(instance_id)
    return instance_id_list


def main(event):
    #variables not stale because they are recomputed from scratch everytime main runs
    ids = get_new_instance_ids(event)
    instances_no_tags = check_tags(ids)
    ec2.stop_instances(InstanceIds=instances_no_tags)
    return f"Instances with no tags {instances_no_tags}"


def lambda_handler(event, context):
    main(event)


if __name__ == "__main__":
    # only runs when this file is executed directly (e.g. local testing),
    # not when AWS Lambda imports it and calls lambda_handler
    # mock)event for testing the logic
    mock_event = {
    "detail": {
        "responseElements": {
            "instancesSet": {
                "items": [
                    {"instanceId": "i-0111111111111aaaa"},
                    {"instanceId": "i-0222222222222bbbb"},
                ]
            }
        }
    }
}
    
    main(mock_event)
