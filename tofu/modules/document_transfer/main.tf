module "secrets" {
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules/aws/secrets"

  project     = "illinois-getchildcare"
  environment = var.environment
  service     = "document-transfer"

  secrets = {
    "consumer/aws" = {
      description     = "AWS Consumer API credentials for the Document Transfer Service."
      recovery_window = var.secret_recovery_period
    },
    "onedrive" = {
      description     = "Credentials for the OneDrive document destination."
      recovery_window = var.secret_recovery_period
      start_value = jsonencode({
        client_id     = ""
        client_secret = ""
        drive_id      = ""
        tenant_id     = ""
      })
    }
  }

  tags = { service = "document-transfer" }
}

module "database" {
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules/aws/serverless_database"

  logging_key_arn = var.logging_key
  secrets_key_arn = module.secrets.kms_key_arn
  vpc_id          = var.vpc_id
  subnets         = data.aws_subnets.private.ids
  ingress_cidrs   = sort([for s in data.aws_subnet.private : s.cidr_block])

  min_capacity        = var.database_capacity_min
  max_capacity        = var.database_capacity_max
  skip_final_snapshot = var.database_skip_final_snapshot
  apply_immediately   = var.database_apply_immediately
  key_recovery_period = var.key_recovery_period
  snapshot_identifier = var.database_snapshot

  project     = "illinois-getchildcare"
  environment = var.environment
  service     = "document-transfer"

  tags = { service = "document-transfer" }
}

# Deploy the Document Transfer service to a Fargate cluster.
module "service" {
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules/aws/fargate_service"

  project                = "illinois-getchildcare"
  project_short          = "il-gcc"
  environment            = var.environment
  service                = "document-transfer"
  service_short          = "doc-trans"
  domain                 = var.domain
  vpc_id                 = var.vpc_id
  private_subnets        = data.aws_subnets.private.ids
  public_subnets         = data.aws_subnets.public.ids
  logging_key_id         = var.logging_key
  container_port         = 3000
  force_delete           = var.force_delete
  image_tags_mutable     = true
  enable_execute_command = true
  public                 = var.public

  ingress_cidrs = var.ingress_cidrs

  environment_variables = {
    RACK_ENV                    = var.service_environment != "" ? var.service_environment : var.environment
    OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4318"
    DATABASE_HOST               = module.database.cluster_endpoint
  }

  environment_secrets = {
    DATABASE_PASSWORD      = "${module.database.secret_arn}:password"
    DATABASE_USER          = "${module.database.secret_arn}:username"
    ONEDRIVE_CLIENT_ID     = "${module.secrets.secrets["onedrive"].secret_arn}:client_id"
    ONEDRIVE_CLIENT_SECRET = "${module.secrets.secrets["onedrive"].secret_arn}:client_secret"
    ONEDRIVE_TENANT_ID     = "${module.secrets.secrets["onedrive"].secret_arn}:tenant_id"
    ONEDRIVE_DRIVE_ID      = "${module.secrets.secrets["onedrive"].secret_arn}:drive_id"
  }

  tags = { service = "document-transfer" }
}

# TODO: Onedrive secrets
module "worker" {
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules/aws/fargate_service"

  project                = "illinois-getchildcare"
  project_short          = "il-gcc"
  environment            = var.environment
  service                = "doc-transfer-worker"
  service_short          = "doc-worker"
  vpc_id                 = var.vpc_id
  private_subnets        = data.aws_subnets.private.ids
  logging_key_id         = var.logging_key
  force_delete           = var.force_delete
  enable_execute_command = true
  create_endpoint        = false
  create_repository      = false
  container_command      = ["./script/worker", "run"]
  image_url              = module.service.repository_url
  repository_arn         = module.service.repository_arn

  environment_variables = {
    RACK_ENV                    = var.service_environment != "" ? var.service_environment : var.environment
    OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4318"
    DATABASE_HOST               = module.database.cluster_endpoint
  }

  environment_secrets = {
    DATABASE_PASSWORD      = "${module.database.secret_arn}:password"
    DATABASE_USER          = "${module.database.secret_arn}:username"
    ONEDRIVE_CLIENT_ID     = "${module.secrets.secrets["onedrive"].secret_arn}:client_id"
    ONEDRIVE_CLIENT_SECRET = "${module.secrets.secrets["onedrive"].secret_arn}:client_secret"
    ONEDRIVE_TENANT_ID     = "${module.secrets.secrets["onedrive"].secret_arn}:drive_id"
    ONEDRIVE_DRIVE_ID      = "${module.secrets.secrets["onedrive"].secret_arn}:tenant_id"
  }

  tags = { service = "document-transfer" }
}
