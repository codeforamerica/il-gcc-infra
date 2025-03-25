# terraform {
#   backend "s3" {
#     bucket         = "illinois-getchildcare-qa-tfstate"
#     key            = "backend.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "qa.tfstate"
#   }
# }

module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=1.1.1"

  project     = "illinois-getchildcare"
  environment = "qa"
}

# Create an S3 bucket and KMS key for logging.
module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=2.1.0"

  project     = "illinois-getchildcare"
  environment = "qa"
}

# Create a VPC with public and private subnets. Since this is a qa
# environment, we'll use a single NAT gateway to reduce costs.
module "vpc" {
  source = "github.com/codeforamerica/tofu-modules-aws-vpc?ref=1.1.1"

  cidr               = "10.0.28.0/22"
  project            = "illinois-getchildcare"
  environment        = "qa"
  single_nat_gateway = true
  logging_key_id     = module.logging.kms_key_arn

  private_subnets = ["10.0.30.0/26", "10.0.30.64/26", "10.0.30.128/26"]
  public_subnets  = ["10.0.28.0/26", "10.0.28.64/26", "10.0.28.128/26"]
}

module "application" {
  source = "../../modules/il_gcc_application"

  environment                  = "qa"
  logging_key                  = module.logging.kms_key_arn
  vpc_id                       = module.vpc.vpc_id
  database_apply_immediately   = true
  database_skip_final_snapshot = true
  database_capacity_min        = 2
  database_capacity_max        = 2
  secret_recovery_period       = 7
  key_recovery_period          = 7
  domain                       = "qa.getchildcareil.org"
  force_delete                 = true
}
