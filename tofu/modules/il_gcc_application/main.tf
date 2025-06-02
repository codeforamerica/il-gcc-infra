resource "aws_ssm_parameter" "version" {
  name        = "/illinois-getchildcare/${var.environment}/version"
  type        = "String"
  value       = "latest"
  description = "Current application image version"

  lifecycle {
    ignore_changes = [value, insecure_value]
  }
}

module "secrets" {
  source = "github.com/codeforamerica/tofu-modules-aws-secrets?ref=1.0.0"

  project     = "illinois-getchildcare"
  environment = var.environment
  service     = "il-gcc-application"

  secrets = {
    "aws" = {
      description = "AWS related configuration."
      recovery_window = var.secret_recovery_period
      start_value = jsonencode({
        aws_bucket = ""
        aws_region = ""
        aws_secret_key = ""
        aws_access_key = ""
      })
    },
    "sendgrid" = {
      description     = "Sendgrid credentials for the IL-GCC application."
      recovery_window = var.secret_recovery_period
      start_value = jsonencode({
        sendgrid_api_key                  = ""
        sendgrid_public_key               = ""
        sendgrid_email_validation_api_key = ""
      })
    },
    "smarty" = {
      description     = "Smarty credentials for the IL-GCC application."
      recovery_window = var.secret_recovery_period
      start_value = jsonencode({
        auth_id    = ""
        auth_token = ""
      })
    },
    "mixpanel" = {
      description     = "Mixpanel credentials for the IL-GCC application."
      recovery_window = var.secret_recovery_period
      start_value = jsonencode({
        api_key = ""
      })
    },
    "google" = {
      description     = "Google credentials for the IL-GCC application."
      recovery_window = var.secret_recovery_period
      start_value = jsonencode({
        encryption_key = ""
      })
    },
    "datadog" = {
      description     = "Datadog credentials for the IL-GCC application."
      recovery_window = var.secret_recovery_period
      start_value = jsonencode({
        api_key                    = ""
        app_key                    = ""
        session_replay_sample_rate = ""
        rum_app_id                 = ""
        rum_client_token           = ""
        environment                = ""
      })
    },
    "sentry" = {
      description     = "Sentry configuration for IL-GCC QA."
      recovery_window = var.secret_recovery_period
      start_value = jsonencode({
        dsn                        = ""
      })
    },
    "jobrunr" = {
      description     = "JobRunr configuration for the IL-GCC application."
      recovery_window = var.secret_recovery_period
      start_value = jsonencode({
        dashboard_enabled      = ""
        enable_background_jobs = ""
      })
    },
    "ccms" = {
      description     = "CCMS credentials for the IL-GCC application."
      recovery_window = var.secret_recovery_period
      start_value = jsonencode({
        ocp_apim_key              = ""
        api_base_url              = ""
        api_username              = ""
        api_password              = ""
        transaction_delay         = ""
        enable_integration        = ""
        ccms_offline_time_ranges  = ""
      })
    },
    "il-gcc" = {
      description     = "IL-GCC application configuration."
      recovery_window = var.secret_recovery_period
      start_value = jsonencode({
        spring_profiles_active            = ""
        convert_uploads_to_pdf            = ""
        converted_file_suffix             = ""
        active_caseload_codes             = ""
        pending_caseload_codes            = ""
        enable_address_validation         = ""
        enable_emails                     = ""
        enable_multiple_providers         = ""
        enable_resource_org_email         = ""
        enable_sendgrid_email_validation  = ""
        enable_dts_integration            = ""
        resource_org_emails               = ""
      })
    }
  }

  tags = { service = "il-gcc-application" }
}

module "database" {
  source = "github.com/codeforamerica/tofu-modules-aws-serverless-database?ref=1.3.0"

  logging_key_arn = var.logging_key
  secrets_key_arn = module.secrets.kms_key_arn
  vpc_id          = var.vpc_id
  subnets         = var.private_subnets
  ingress_cidrs   = ["10.0.28.0/22"]
  force_delete    = var.force_delete

  min_capacity        = var.database_capacity_min
  max_capacity        = var.database_capacity_max
  skip_final_snapshot = var.database_skip_final_snapshot
  apply_immediately   = var.database_apply_immediately
  key_recovery_period = var.key_recovery_period
  snapshot_identifier = var.database_snapshot
  instances     = var.database_instance_count

  project     = "illinois-getchildcare"
  environment = var.environment
  service     = "app"

  tags = { service = "app" }
}

# Deploy the IL-GCC Application to a Fargate cluster.
module "service" {
  source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.2.1"
  project                = "illinois-getchildcare"
  project_short          = "il-gcc"
  environment            = var.environment
  service                = "app"
  service_short          = "app"
  domain                 = var.domain
  subdomain              = var.subdomain
  vpc_id                 = var.vpc_id
  private_subnets        = var.private_subnets
  public_subnets         = var.public_subnets
  logging_key_id         = var.logging_key
  container_port         = 8080
  force_delete           = var.force_delete
  create_endpoint        = true
  image_tags_mutable     = true
  version_parameter      = aws_ssm_parameter.version.name
  enable_execute_command = true
  public                 = var.public
  health_check_path       = "/actuator/health"

  environment_variables = {
    DATABASE_HOST = module.database.cluster_endpoint
  }

  environment_secrets = {
      DATABASE_PASSWORD                  = "${module.database.secret_arn}:password"
      DATABASE_USER                      = "${module.database.secret_arn}:username"
      SENDGRID_API_KEY                   = "${module.secrets.secrets["sendgrid"].secret_arn}:sendgrid_api_key"
      SENDGRID_PUBLIC_KEY                = "${module.secrets.secrets["sendgrid"].secret_arn}:sendgrid_public_key"
      SENDGRID_EMAIL_VALIDATION_API_KEY  = "${module.secrets.secrets["sendgrid"].secret_arn}:sendgrid_email_validation_api_key"
      SMARTY_AUTH_ID                     = "${module.secrets.secrets["smarty"].secret_arn}:auth_id"
      SMARTY_AUTH_TOKEN                  = "${module.secrets.secrets["smarty"].secret_arn}:auth_token"
      MIXPANEL_API_KEY                   = "${module.secrets.secrets["mixpanel"].secret_arn}:api_key"
      ENCRYPTION_KEY                     = "${module.secrets.secrets["google"].secret_arn}:encryption_key"
      DATADOG_API_KEY                    = "${module.secrets.secrets["datadog"].secret_arn}:api_key"
      DATADOG_APPLICATION_KEY            = "${module.secrets.secrets["datadog"].secret_arn}:app_key"
      DATADOG_SESSION_REPLAY_SAMPLE_RATE = "${module.secrets.secrets["datadog"].secret_arn}:session_replay_sample_rate"
      DATADOG_RUM_APPLICATION_ID         = "${module.secrets.secrets["datadog"].secret_arn}:rum_app_id"
      DATADOG_RUM_CLIENT_TOKEN           = "${module.secrets.secrets["datadog"].secret_arn}:rum_client_token"
      DATADOG_ENVIRONMENT                = "${module.secrets.secrets["datadog"].secret_arn}:environment"
      SENTRY_DSN                         = "${module.secrets.secrets["sentry"].secret_arn}:dsn"
      JOBRUNR_DASHBOARD_ENABLED          = "${module.secrets.secrets["jobrunr"].secret_arn}:dashboard_enabled"
      ENABLE_BACKGROUND_JOBS_FLAG        = "${module.secrets.secrets["jobrunr"].secret_arn}:enable_background_jobs"
      OCP_APIM_SUBSCRIPTION_KEY          = "${module.secrets.secrets["ccms"].secret_arn}:ocp_apim_key"
      CCMS_API_BASE_URL                  = "${module.secrets.secrets["ccms"].secret_arn}:api_base_url"
      CCMS_API_USERNAME                  = "${module.secrets.secrets["ccms"].secret_arn}:api_username"
      CCMS_API_PASSWORD                  = "${module.secrets.secrets["ccms"].secret_arn}:api_password"
      CCMS_TRANSACTION_DELAY_MINUTES     = "${module.secrets.secrets["ccms"].secret_arn}:transaction_delay"
      ENABLE_CCMS_INTEGRATION            = "${module.secrets.secrets["ccms"].secret_arn}:enable_integration"
      CCMS_OFFLINE_TIME_RANGES           = "${module.secrets.secrets["ccms"].secret_arn}:ccms_offline_time_ranges"
      WAIT_FOR_PROVIDER_RESPONSE         = "${module.secrets.secrets["il-gcc"].secret_arn}:wait_for_provider_response"
      ALLOW_PROVIDER_REGISTRATION        = "${module.secrets.secrets["il-gcc"].secret_arn}:allow_provider_registration"
      CONVERT_UPLOADS_TO_PDF             = "${module.secrets.secrets["il-gcc"].secret_arn}:convert_uploads_to_pdf"
      CONVERTED_FILE_SUFFIX              = "${module.secrets.secrets["il-gcc"].secret_arn}:converted_file_suffix"
      SPRING_PROFILES_ACTIVE             = "${module.secrets.secrets["il-gcc"].secret_arn}:spring_profiles_active"
      ACTIVE_CASELOAD_CODES              = "${module.secrets.secrets["il-gcc"].secret_arn}:active_caseload_codes"
      PENDING_CASELOAD_CODES             = "${module.secrets.secrets["il-gcc"].secret_arn}:pending_caseload_codes"
      ADDRESS_VALIDATION_ENABLED         = "${module.secrets.secrets["il-gcc"].secret_arn}:enable_address_validation"
      ENABLE_EMAILS_FLAG                 = "${module.secrets.secrets["il-gcc"].secret_arn}:enable_emails"
      ENABLE_MULTIPLE_PROVIDERS          = "${module.secrets.secrets["il-gcc"].secret_arn}:enable_multiple_providers"
      ENABLE_RESOURCE_ORG_EMAIL          = "${module.secrets.secrets["il-gcc"].secret_arn}:enable_resource_org_email"
      ENABLE_SENDGRID_EMAIL_VALIDATION   = "${module.secrets.secrets["il-gcc"].secret_arn}:enable_sendgrid_email_validation"
      RESOURCE_ORG_EMAILS                = "${module.secrets.secrets["il-gcc"].secret_arn}:resource_org_emails"

      AWS_BUCKET                         = "${module.secrets.secrets["aws"].secret_arn}:aws_bucket"
      AWS_REGION                         = "${module.secrets.secrets["aws"].secret_arn}:aws_region"
      AWS_SECRET_KEY                     = "${module.secrets.secrets["aws"].secret_arn}:aws_secret_key"
      AWS_ACCESS_KEY                     = "${module.secrets.secrets["aws"].secret_arn}:aws_access_key"
    }
}

module "worker" {
  source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.2.1"

  project                = "illinois-getchildcare"
  project_short          = "il-gcc"
  stats_prefix           = "illinois-getchildcare/qa"
  environment            = var.environment
  service                = "worker"
  service_short          = "worker"
  vpc_id                 = var.vpc_id
  private_subnets        = var.private_subnets
  logging_key_id         = var.logging_key
  force_delete           = var.force_delete
  enable_execute_command = true
  create_endpoint        = false
  create_repository      = false
  container_command      = ["./script/worker", "run"]
  image_url              = module.service.repository_url
  version_parameter      = aws_ssm_parameter.version.name
  repository_arn         = module.service.repository_arn

  environment_variables = {
    DATABASE_HOST = module.database.cluster_endpoint
    AWS_BUCKET    = "get-child-care-illinois-${var.environment}"
  }

  tags = { service = "application-worker" }
}
