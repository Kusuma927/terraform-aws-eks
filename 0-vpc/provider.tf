terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket="82s-terraf-remote-state"
    key="expense-dev-eks-vpc"
    region="us-east-1"
    dynamodb_table = "82s-terra-state-locking"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}