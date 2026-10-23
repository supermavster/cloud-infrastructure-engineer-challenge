variable "project" {
  description = "Short project name used as the prefix of every resource name."
  type        = string
  default     = "info-api"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}$", var.project))
    error_message = "project must be 2-20 characters: lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Deployment environment. Selects the settings profile in environments/<env>/."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "region" {
  description = "AWS region to deploy into, for example us-east-1."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "region must look like us-east-1."
  }
}

variable "owner" {
  description = "Owner tag applied to every resource."
  type        = string
}

variable "allowed_account_ids" {
  description = "AWS account IDs Terraform may run against. Leave empty to disable the guard."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.allowed_account_ids : can(regex("^[0-9]{12}$", id))])
    error_message = "Each account ID must be exactly 12 digits."
  }
}

variable "kms_deletion_window_in_days" {
  description = "Days a KMS key stays recoverable after deletion is scheduled (7-30)."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "kms_deletion_window_in_days must be between 7 and 30."
  }
}

variable "vpc_cidr_block" {
  description = "IPv4 CIDR of the VPC. Subnets are /24 blocks carved from it, so use /16 or larger."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across (2 or 3)."
  type        = number
  default     = 2
}

variable "nat_gateway_mode" {
  description = "single shares one NAT gateway across zones (cheaper). per_az gives each zone its own, so one zone failing does not cut egress for the others."
  type        = string
}

variable "flow_log_retention_days" {
  description = "Days to keep VPC flow logs."
  type        = number
}
