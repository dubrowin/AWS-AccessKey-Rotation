# AWS-AccessKey-Rotation
Solution to automatically rotate AWS Access Keys and enable remote machines to download the updated keys themselves

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
