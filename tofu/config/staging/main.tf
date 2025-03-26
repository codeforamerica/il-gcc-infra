terraform {
  backend "s3" {
    bucket         = "illinois-getchildcare-staging-tfstate"
    key            = "backend.tfstate"
    region         = "us-east-1"
    dynamodb_table = "staging.tfstate"
  }
}

module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=1.0.0"

  project     = "illinois-getchildcare"
  environment = "staging"
}

# Create hosted zones for DNS.
module "hosted_zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 3.1"

  zones = {
    document_transfer = {
      domain_name = "staging.document-transfer.cfa.codes"
      comment     = "Hosted zone for the Document Transfer service."
    }
  }
}

# Create an S3 bucket and KMS key for logging.
module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=1.2.1"

  project     = "illinois-getchildcare"
  environment = "staging"
}

# Create a VPC with public and private subnets. Since this is a staging
# environment, we'll use a single NAT gateway to reduce costs.
module "vpc" {
  source = "github.com/codeforamerica/tofu-modules-aws-vpc?ref=1.1.1"

  cidr               = "10.0.20.0/22"
  project            = "illinois-getchildcare"
  environment        = "staging"
  single_nat_gateway = true
  logging_key_id     = module.logging.kms_key_arn

  private_subnets = ["10.0.22.0/26", "10.0.22.64/26", "10.0.22.128/26"]
  public_subnets  = ["10.0.20.0/26", "10.0.20.64/26", "10.0.20.128/26"]

  peers = {
    "aptible" : {
      account_id : "916150859591",
      vpc_id : "vpc-041ed50bbc0467be5",
      region : "us-east-1",
      cidr : "10.226.0.0/16"
    }
  }
}

# Create a bastion host for access to the VPC over SSM.
module "bastion" {
  source = "github.com/codeforamerica/tofu-modules-aws-ssm-bastion?ref=1.0.0"

  project                 = "illinois-getchildcare"
  environment             = "staging"
  key_pair_name           = "ssm-bastion-test"
  private_subnet_ids      = module.vpc.private_subnets
  vpc_id                  = module.vpc.vpc_id
  kms_key_recovery_period = 7
}

module "microservice" {
  source = "../../modules/document_transfer"

  environment                  = "staging"
  logging_key                  = module.logging.kms_key_arn
  vpc_id                       = module.vpc.vpc_id
  database_apply_immediately   = true
  database_skip_final_snapshot = true
  database_capacity_min        = 2
  database_capacity_max        = 2
  secret_recovery_period       = 7
  key_recovery_period          = 7
  domain                       = "staging.document-transfer.cfa.codes"
  force_delete                 = true

  # Allow access from the peered web application.
  ingress_cidrs = ["10.226.0.0/16"]
}
