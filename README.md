# AWS-AccessKey-Rotation
Solution to automatically rotate AWS Access Keys and enable remote machines to download the updated keys themselves

![automated-key-replacement](https://github.com/user-attachments/assets/18af3208-1345-44d4-9fd9-f4213bbeee6c)

## Initialization Steps
- Create the update Bucket
  - I used versioning with a lifecycle policy that keeps 5 old versions around, just in case
- Create the Parameter Stores to be used, currently they all need to be in the same region
- Create a cron job that runs daily to check for updates

## To Do
- Create the Lambda that does the automated rotation
  - The Lambda should run monthly, this gives each system up to a month to update itself
  - Anything that isn't updating, you can see in the Update Bucket since it's hostname based file won't be updating
