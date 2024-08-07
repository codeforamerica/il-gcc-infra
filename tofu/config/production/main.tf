terraform {
  backend "s3" {
    bucket = "illinois-getchildcare-prod-tfstate"
    key    = "backend.tfstate"
    region = "us-east-1"
  }
}

module "backend" {
  # TODO: Create releases for tofu-modules and pin to a release.
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules/aws/backend"

  project     = "illinois-getchildcare"
  environment = "prod"
}

# Create hosted zones for DNS.
module "hosted_zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 3.1"

  zones = {
    document_transfer = {
      domain_name = "illinois.document-transfer.cfa.codes"
      comment     = "Hosted zone for the Document Transfer service."
    }
  }
}

# Create an S3 bucket and KMS key for logging.
module "logging" {
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules/aws/logging"

  project     = "illinois-getchildcare"
  environment = "prod"
}

# Create a VPC with public and private subnets.
module "vpc" {
  # tflint-ignore: terraform_module_pinned_source
  source     = "github.com/codeforamerica/tofu-modules/aws/vpc"
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

module "secrets" {
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules/aws/secrets"

  project     = "illinois-getchildcare"
  environment = "production"
  service     = "document-transfer"

  secrets = {
    "consumer/aws" = {
      description     = "AWS Consumer API credentials for the Document Transfer Service."
      recovery_window = 7
    }
  }
}

module "database" {
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules/aws/serverless_database"

  logging_key_arn = module.logging.kms_key_arn
  secrets_key_arn = module.secrets.kms_key_arn
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.private_subnets
  ingress_cidrs   = module.vpc.private_subnets_cidr_blocks

  min_capacity        = 2
  max_capacity        = 2
  skip_final_snapshot = false
  apply_immediately   = true
  key_recovery_period = 30
  snapshot_identifier = "arn:aws:rds:us-east-1:211125423013:cluster-snapshot:prod-cluster-pre-cmk"

  project     = "illinois-getchildcare"
  environment = "production"
  service     = "document-transfer"
}

# Deploy the Document Transfer service to a Fargate cluster.
module "document_transfer" {
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules/aws/fargate_service"

  project                = "illinois-getchildcare"
  project_short          = "il-gcc"
  environment            = "prod"
  service                = "document-transfer"
  service_short          = "doc-trans"
  domain                 = "illinois.document-transfer.cfa.codes"
  vpc_id                 = module.vpc.vpc_id
  private_subnets        = module.vpc.private_subnets
  public_subnets         = module.vpc.public_subnets
  logging_key_id         = module.logging.kms_key_arn
  container_port         = 3000
  image_tags_mutable     = true
  enable_execute_command = true

  # Only allow access from the web application and its workers.
  public = false

  environment_variables = {
    RACK_ENV                    = "production"
    OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4318"
    DATABASE_HOST               = module.database.cluster_endpoint
  }

  environment_secrets = {
    DATABASE_PASSWORD      = "${module.database.secret_arn}:password"
    DATABASE_USER          = "${module.database.secret_arn}:username"
    ONEDRIVE_CLIENT_ID     = "onedrive:client_id"
    ONEDRIVE_CLIENT_SECRET = "onedrive:client_secret"
    ONEDRIVE_TENANT_ID     = "onedrive:tenant_id"
    ONEDRIVE_DRIVE_ID      = "onedrive:drive_id"
  }

  secrets_manager_secrets = {
    onedrive = {
      recovery_window = 7
      description     = "Credentials for the OneDrive."
    }
  }
}
