terraform {
  backend "s3" {
    bucket         = "illinois-getchildcare-prod-tfstate"
    key            = "backend.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prod.tfstate"
  }
}

module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=1.1.1"

  project     = "illinois-getchildcare"
  environment = "prod"
}

# Create hosted zones for DNS.
module "hosted_zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 5.0"

  zones = {
    document_transfer = {
      domain_name = "illinois.document-transfer.cfa.codes"
      comment     = "Hosted zone for the Document Transfer service."
    }
  }
}

# Create an S3 bucket and KMS key for logging.
module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=2.1.0"

  project     = "illinois-getchildcare"
  environment = "prod"
}

# Create a VPC with public and private subnets.
module "vpc" {
  source     = "github.com/codeforamerica/tofu-modules-aws-vpc?ref=1.1.1"
  depends_on = [module.logging]

  cidr           = "10.0.24.0/22"
  project        = "illinois-getchildcare"
  environment    = "prod"
  logging_key_id = module.logging.kms_key_arn

  private_subnets = ["10.0.26.0/26", "10.0.26.64/26", "10.0.26.128/26"]
  public_subnets  = ["10.0.24.0/26", "10.0.24.64/26", "10.0.24.128/26"]

  peers = {
    "aptible" : {
      account_id : "916150859591",
      vpc_id : "vpc-0db67f7bfa9c61a06",
      region : "us-east-1",
      cidr : "10.65.0.0/16"
    }
  }
}

# Create a bastion host for access to the VPC over SSM.
module "bastion" {
  source = "github.com/codeforamerica/tofu-modules-aws-ssm-bastion?ref=1.0.0"

  project                 = "illinois-getchildcare"
  environment             = "prod"
  private_subnet_ids      = module.vpc.private_subnets
  vpc_id                  = module.vpc.vpc_id
  kms_key_recovery_period = 30
}

module "microservice" {
  source = "../../modules/document_transfer"

  environment           = "prod"
  stats_environment     = "production"
  logging_key           = module.logging.kms_key_arn
  vpc_id                = module.vpc.vpc_id
  database_capacity_min = 2
  database_capacity_max = 2
  domain                = "illinois.document-transfer.cfa.codes"
  database_snapshot     = "arn:aws:rds:us-east-1:211125423013:cluster-snapshot:prod-cluster-env-update"

  # Allow access from the peered web application.
  ingress_cidrs = ["10.65.0.0/16"]
}
