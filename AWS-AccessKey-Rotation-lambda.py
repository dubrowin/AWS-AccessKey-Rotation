import json
import boto3
import re


# Create AWS clients
iam = boto3.client('iam')
ssm = boto3.client('ssm')

def lambda_handler(event, context):

    # Get the username from the event input
    username = 'param-test'
    # List the access keys for the user
    response = iam.list_access_keys(UserName=username)

    # Count the number of active access keys
    active_keys = [key for key in response['AccessKeyMetadata'] if key['Status'] == 'Active']
    num_active_keys = len(active_keys)

    # If the user has two active access keys, delete the older one
    if num_active_keys == 2:
        # Sort the active keys by creation date
        active_keys.sort(key=lambda x: x['CreateDate'])

        # Delete the older access key
        older_key = active_keys[0]
        iam.delete_access_key(
            UserName=username,
            AccessKeyId=older_key['AccessKeyId']
        )

    # Get the data from the Parameter Store
    # Retrieve the parameter value from AWS Systems Manager

    parameter_name = 'param-test'
    response = ssm.get_parameter(Name=parameter_name, WithDecryption=True)
    parameter_store_value = response["Parameter"]["Value"]

    # Remove the data from "OLD" to the bottom
    old_data_start = parameter_store_value.find("OLD")

    if old_data_start != -1:
        parameter_store_value = parameter_store_value[:old_data_start]

    # Replace "NEW" with "OLD"
    OLDKEY = re.sub(r"NEW\b", "\nOLD", parameter_store_value)

    print("OLDKEY", OLDKEY)


    # Create new access keys for the user 'param-test'
    response = iam.create_access_key(UserName=username)
    
    # Extract the access key ID and secret access key
    access_key_id = response['AccessKey']['AccessKeyId']
    secret_access_key = response['AccessKey']['SecretAccessKey']
    
    print("response", response)
    
    NEWKEY="NEW\naws_access_key_id = " + access_key_id + "\naws_secret_access_key = " + secret_access_key + OLDKEY

    print("NEWKEY", NEWKEY)

    # Store the access keys in AWS Parameter Store
    ssm.put_parameter(
        Name='param-test',
        Value=NEWKEY,
        Type='String',
        Overwrite=True
    )
    

    return {
        'statusCode': 200,
        'body': json.dumps('Access keys created and stored successfully.')
    }
