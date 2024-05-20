terraform {
  backend "s3" {
    bucket = "illinois-getchildcare-staging-tfstate"
    key    = "backend.tfstate"
    region = "us-east-1"
  }
}

module "backend" {
  # TODO: Create releases for tofu-modules and pin to a release.
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules/aws/backend"

  project     = "illinois-getchildcare"
  environment = "staging"
}

# Create an S3 bucket and KMS key for logging.
module "logging" {
  source = "github.com/codeforamerica/tofu-modules/aws/logging"

  project     = "illinois-getchildcare"
  environment = "staging"
}

# Create a VPC with public and private subnets. Since this is a staging
# environment, we'll use a single NAT gateway to reduce costs.
module "vpc" {
  source = "github.com/codeforamerica/tofu-modules/aws/vpc"

  cidr               = "10.0.20.0/22"
  project            = "illinois-getchildcare"
  environment        = "staging"
  single_nat_gateway = true
  logging_key_id     = module.logging.kms_key_arn

  private_subnets = ["10.0.22.0/26", "10.0.22.64/26", "10.0.22.128/26"]
  public_subnets  = ["10.0.20.0/26", "10.0.20.64/26", "10.0.20.128/26"]
}

# Deploy the Document Transfer service to a Fargate cluster.
module "document_transfer" {
  source = "github.com/codeforamerica/tofu-modules/aws/fargate_service"

  project         = "illinois-getchildcare"
  project_short   = "il-gcc"
  environment     = "staging"
  service         = "document-transfer"
  service_short   = "doc-trans"
  domain          = "staging.document-transfer.cfa.codes"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  logging_key_id  = module.logging.kms_key_arn
  container_port  = 3000
  force_delete    = true
}

# Display commands to push the Docker image to ECR.
output "document_transfer_docker_push" {
  value = module.document_transfer.docker_push
}
