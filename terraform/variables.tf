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
