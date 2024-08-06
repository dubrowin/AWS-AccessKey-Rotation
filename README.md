# AWS-AccessKey-Rotation

When I think about my own use of AWS Access Keys, they are either for on-prem (in my house) machines and/or backup purposes. Changing the Access Keys wouldn't be hard, but would take time. So I started to think about a way to automate the process and give enough time for all the machines to update. Given that a given IAM user can have up to 2 Access Keys, I put together this solution. A Lambda is scheduled to run monthly and updates the Access Keys so that the older one gets deleted, the one that's left is relegated as "old" and a new Access Key is created. And there is a script to be run on the individual hosts, I'm thinking daily, so that they will check if a new key is available. When a new key is found (in Parameter Store), they'll update their AWS CLI Configuration with the new key and report in that they've updated by posting a file to an S3 bucket.

![automated-key-replacement](https://github.com/user-attachments/assets/18af3208-1345-44d4-9fd9-f4213bbeee6c)

## Initialization Steps
- Create the update Bucket
  - I suggest using the account-id in the name
    - ```<account id>-accesskey-update```
  - I used versioning with a lifecycle policy that keeps 5 old versions around, just in case 

- Create Parameter Store Parameter with the existing key (I pulled mine out of the .aws/config file)
 - All the Parameter Stores supported by 1 script must currently be in the same region
 - Type: String
```Example Value:
NEW
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
```

- Ensure the Key owner has the right permissions to access the Parameter Store
 - The required permission can be found in: script-iam-permission.json
   - NOTE: The permission will need to be updated to include your specific resources
     - ```<REGION>```
     - ```<ACCOUNT ID>```
     - ```param-test``` and/or ```backup-test``` should be your parameter store resource
 - The key will also need access to the S3 bucket, the required access can be found in: s3-update.json
   - **NOTE:** The permission will need to be updated to include your specific resources
     - ```<BUCKET>```
 - verify access using the AWS CLI to the Parameter Store

```aws ssm get-parameter --name <param-name>```

You may need to include the region and/or profile

```aws ssm get-parameter --name <param-name> --region <region> --profile <profile name>```

Create the Lambda

- Function Name (I am using a seperate function per key)
- Runtime: Python, whatever the latest is, mine is 3.11
- Architecture: I chose ARM since it's more cost efficient
- Create Function

Configuration:
- General configuration
  - Timeout: 30 sec
- Permissions:
  - Add in IAM policies from 
    - ```Parameter-Store-Push-Params-4-Lambda.json```
      - Update
        - ```<REGION>```
        - ```<ACCOUNT ID>```
        - ```<Parameter Store>```
    - ```IAM-Key-Mgmt-policy-4-Lambda.json```
      - Update
        - ```<ACCOUNT ID>```
        - ```<USER NAME>```
Copy the code from AWS-AccessKey-Rotation-lambda.py into the Lambda code window
 - Update Line 13 with the IAM user name
 - Update Line 27 & 67 with the Parameter Store Parameter
   - **TODO:** make both of these an Environment Variable
   - **TODO:** Update the Lambda so that 67 and 27 use a Variable

Repeat for each Lambda/Key you want to use


Event Bridge Scheduler
- Name the schedule
- Recurring
- set when you want it happen
  - I set mine for a rate based schedule of 30 days and a flexible time window of 4 hours
- Select Lambda
  - find the lambda you just created


I then created a test in Lambda with dummy data and executed, followed by the aws cli command to verify what was now in parameter store

Deploy the shell script ```param-update.sh``` onto the machine
- Update:
  - ```PARAMS```
  - ```PARAMREGION```
  - ```UPDATEBUCKET```
  - ```PROFILE``` if needed
- run it to see that it works, output will be displayed on the terminal

Schedule via cron
- update the path below
- you can update the timing, this runs at 02:09 every morning
- all logs go to the standard log (syslog or journalctl)
```# Run Backup Script Nightly at 1am
#0 1 * * *  /home/shlomo/scripts/rbackup
#| | | | |
#| | | | +-- day of week 0-7 (0 or 7 is Sun, or use names)
#| | | +-- month 1-12 (or names, see crontab (5))
#| | +-- day of month 1-31
#| +-- hour 0-23
#+-- minute 0-59
#*/5 * * * * /home/shlomo/scripts/param-update.sh
9 2 * * * /path/to/script/param-update.sh
```





## To Do
- The Lambda currently does not take an evironment variable of the parameters/users to change, this should get updated to allow for easier configuration.
- The Lambda currently can only handle 1 parameter store and user, so it would need to be replicated per use.
- The AWS resources should be a CloudFormation template for easier setup
  - Might be able to even deploy the bash script to the S3 updater bucket with some of the parameters pre-defined.
- ~~Install on another account so I can capture accurate installation/setup instructions.~~
