variable "database_apply_immediately" {
  type        = bool
  description = "Whether to apply changes to the database cluster immediately rather than during the next maintenance window."
  default     = false
}

variable "database_capacity_max" {
  description = "The maximum capacity of the database."
  type        = number
  default     = 10
}

variable "database_capacity_min" {
  description = "The minimum capacity of the database."
  type        = number
  default     = 2
}

variable "database_skip_final_snapshot" {
  type        = bool
  description = "Whether to skip the final snapshot when destroying the database cluster."
  default     = false
}

variable "database_snapshot" {
  type        = string
  description = "Optional name or ARN of the snapshot to restore the cluster from. Only applicable on create."
  default     = ""
}

variable "domain" {
  description = "The domain name for the service."
  type        = string
}

variable "environment" {
  description = "The environment in which the service is being deployed."
  type        = string
  default     = "development"
}

variable "force_delete" {
  type        = bool
  description = "Force deletion of resources. If changing to true, be sure to apply before destroying."
  default     = false
}

variable "ingress_cidrs" {
  description = "The CIDR blocks to allow ingress from. The current VPC is allowed by default."
  type        = list(string)
  default     = []
}

variable "key_recovery_period" {
  type        = number
  default     = 30
  description = "Recovery period for deleted KMS keys in days. Must be between 7 and 30."

  validation {
    condition     = var.key_recovery_period > 6 && var.key_recovery_period < 31
    error_message = "Recovery period must be between 7 and 30."
  }
}

variable "logging_key" {
  description = "The ARN of the KMS key used for logging."
  type        = string
}

variable "public" {
  type        = bool
  description = "Launch the service so that it is available on the public Internet."
  default     = true
}

variable "secret_recovery_period" {
  type        = number
  default     = 30
  description = "Recovery period for deleted secrets in days. Must be between 7 and 30, or 0 to force delete immediately."

  validation {
    condition     = var.secret_recovery_period == 0 || var.secret_recovery_period > 6 && var.secret_recovery_period < 31
    error_message = "Recovery period must be between 7 and 30."
  }
}

variable "service_environment" {
  description = "The environment the service should operate in, if different from environment."
  type        = string
  default     = ""
}

variable "stats_environment" {
  description = "The environment the stats client should operate in, if different from environment. Use \"staging\" or \"production\" to send stats to the collector."
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "The ID of the VPC in which the service is deployed."
  type        = string
}
