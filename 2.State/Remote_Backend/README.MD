# Terraform State 
Every time you run Terraform, it records information about what infrastructure it created in a Terraform state file.


# Problem 
If you’re using Terraform for a personal project, storing state in a single
terraform.tfstate file that lives locally on your computer works just fine. But
if you want to use Terraform as a team on a real product, you run into
several problems:

 - Shared storage for state files
 - Manual error
 - Secrets


# Solution

Remote backends solve all three of the issues just listed:

## Techology needed
 - Terraform v1.2.6
 - AWS account 

## Requirements

 - Amazon S3 (Simple Storage Service)
 - Dynamo Db table

## Steps

Follow these steps to set up the s3 and dynamo db table on the main.tf file:

1. Set up your provider 
```
Terraform init 

```
2. Run terraform
```
Terraform apply 

```

Note: If using IAM user, please verify permissions to create S3 buckets

3. Configure backend

After everything is set up, we need to configure the backend using the following syntax:

```

terraform {
  backend "s3" {
    bucket = "<NAME_OF_BUCKET>"
    key = "global/s3/terraform.tfstate"
    region = "<REGION_OF_S3"

    #Replace this with your DynamoDb table name
    dynamodb_endpoint = "<DYNAMO_TABLE_NAME>"
    encrypt = true 
  }
}
 

```
4. Set the backend 

To instruct terraform to store your state file in the S3 bucket, use the init command to configure backend


```
terraform init 
```

If everthing was correctly configure you will check out a message on the terminal like this:

```

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

```

## Validate state is configure

Add the following output code on the main.tf file and checkout if state is stored on s3

```
output "s3_bucket_arn"{
 value = aws_s3_bucket.terraform_state.arn
 description = "The name of the s3 bucket"

}
output "dynamodb_table_name"{
    value = aws_dynamodb_table.terraform_locks.name
    description = " The name of DynamoDb"
}
```
