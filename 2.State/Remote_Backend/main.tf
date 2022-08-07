
variable "s3BucketName" {
  type = string
  default = "s-devsessions-terraform"
}
variable "dynamoTableName" {
  type = string
  default = "db-devsessions-table-state"
}
provider "aws" {
  region = "us-east-2"
  shared_credentials_files = ["$Home/.aws/credentials"]

}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.s3BucketName}"

   
  force_destroy = true #Set to True  destroy environment
  
  lifecycle {
    prevent_destroy = false #set to True to prevent accidental deletion
  }
  #To support versioning
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name = "${var.dynamoTableName}"  
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockId"

  attribute {
    name = "LockId"
    type = "S"
  }


}
output "s3_bucket_arn"{
 value = aws_s3_bucket.terraform_state.arn
 description = "The name of the s3 bucket"

}
output "dynamodb_table_name"{
    value = aws_dynamodb_table.terraform_locks.name
    description = " The name of DynamoDb"
}