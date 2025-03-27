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

# Create hosted zones for DNS.
module "hosted_zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 5.0"

  zones = {
    document_transfer = {
      domain_name = "development.document-transfer.cfa.codes"
      comment     = "Hosted zone for the Document Transfer service."
      tags        = { service = "document-transfer" }
    }
  }
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

module "microservice" {
  source = "../../modules/document_transfer"

  environment                  = "development"
  stats_environment            = "staging"
  logging_key                  = module.logging.kms_key_arn
  vpc_id                       = module.vpc.vpc_id
  database_apply_immediately   = true
  database_skip_final_snapshot = true
  database_capacity_min        = 2
  database_capacity_max        = 2
  secret_recovery_period       = 0
  key_recovery_period          = 7
  domain                       = "development.document-transfer.cfa.codes"
  force_delete                 = true
  public                       = true
}
