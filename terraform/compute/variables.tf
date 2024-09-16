variable "aws_profile" {
  description = "The AWS profile to use for SSH connections"
  type        = string
  default     = "default"
}

variable "aws_access_key_id" {
  description = "The AWS access key ID"
  type        = string
  default     = null
}

variable "aws_secret_access_key" {
  description = "The AWS secret access key"
  type        = string
  default     = null
}

variable "region" {
  description = "The region where the resources will be provisioned"
  type        = string
  default     = "us-east-1"
}

variable "main_organization" {
  description = "The main organization name"
  type        = string
  default     = "default"

}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
  default     = "12345678910"
}