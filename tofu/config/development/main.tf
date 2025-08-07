terraform {
  backend "s3" {
    bucket         = "illinois-getchildcare-development-tfstate"
    key            = "backend.tfstate"
    region         = "us-east-1"
    dynamodb_table = "development.tfstate"
  }
}

module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=1.1.1"

  project     = "illinois-getchildcare"
  environment = "development"
}

# Create an S3 bucket and KMS key for logging.
module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=2.1.0"

  project     = "illinois-getchildcare"
  environment = "development"
}

# Create a VPC with public and private subnets. Since this is a development
# environment, we'll use a single NAT gateway to reduce costs.
module "vpc" {
  source = "github.com/codeforamerica/tofu-modules-aws-vpc?ref=1.1.0"

  cidr               = "10.0.20.0/22"
  project            = "illinois-getchildcare"
  environment        = "development"
  single_nat_gateway = true
  logging_key_id     = module.logging.kms_key_arn

  private_subnets = ["10.0.22.0/26", "10.0.22.64/26", "10.0.22.128/26"]
  public_subnets  = ["10.0.20.0/26", "10.0.20.64/26", "10.0.20.128/26"]
}
