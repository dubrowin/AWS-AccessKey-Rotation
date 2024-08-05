# AWS-AccessKey-Rotation

When I think about my own use of AWS Access Keys, they are either for on-prem (in my house) machines and/or backup purposes. Changing the Access Keys wouldn't be hard, but would take time. So I started to think about a way to automate the process and give enough time for all the machines to update. Given that a given IAM user can have up to 2 Access Keys, I put together this solution. A Lambda is scheduled to run monthly and updates the Access Keys so that the older one gets deleted, the one that's left is relegated as "old" and a new Access Key is created. And there is a script to be run on the individual hosts, I'm thinking daily, so that they will check if a new key is available. When a new key is found (in Parameter Store), they'll update their AWS CLI Configuration with the new key and report in that they've updated by posting a file to an S3 bucket.

![automated-key-replacement](https://github.com/user-attachments/assets/18af3208-1345-44d4-9fd9-f4213bbeee6c)

## Initialization Steps
- Create the update Bucket
  - I used versioning with a lifecycle policy that keeps 5 old versions around, just in case
- Create the Parameter Stores to be used, currently they all need to be in the same region
- Create a cron job that runs daily to check for updates

## To Do
- The Lambda currently does not take an evironment variable of the parameters/users to change, this should get updated to allow for easier configuration.
- The Lambda currently can only handle 1 parameter store and user, so it would need to be replicated per use.
- Install on another account so I can capture accurate installation/setup instructions.
