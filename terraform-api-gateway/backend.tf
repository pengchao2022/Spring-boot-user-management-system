terraform {
  backend "s3" {
    bucket = "terraformstatefile090909"
    key    = "user-management-api-gateway/terraform.tfstate"
    region = "us-east-1"
  }
}