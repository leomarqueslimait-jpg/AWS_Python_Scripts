import boto3
from botocore.exceptions import ClientError
import csv

s3 = boto3.client('s3')
responses = s3.list_buckets()
buckets = responses["Buckets"]
bucket_names = []
for bucket in buckets:
    bucket_names.append(bucket["Name"])

bucket_rules = []
def encryption_config():
    
    for bucket in bucket_names:
        try:
            response = s3.get_bucket_encryption(Bucket=bucket)
            rules = response["ServerSideEncryptionConfiguration"]["Rules"]
            bucket_rules.append((bucket, rules))
        except ClientError as e:
            if e.response['Error']['Code'] == 'ServerSideEncryptionConfigurationNotFoundError':
                print(f"{bucket}: NOT encrypted")
            else:
                raise

encryption_config() 
dict_bucket = []
def transform_list():
    for bucket in bucket_rules:
        x = bucket[0]
        y = bucket[1]
        dict_bucket.append({"bucket": x, "encryption": y})

transform_list()
"""
for bucket in dict_bucket:
    print(f"bucket: {bucket['bucket']}, encryption: {bucket['Encryption']}")"""

def to_csv():

    with open("buckets.csv", "w") as file:
        writer = csv.DictWriter(file, fieldnames=["bucket", "encryption"])
        writer.writeheader()
        writer.writerows(dict_bucket)
        

to_csv()