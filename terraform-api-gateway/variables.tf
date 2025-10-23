variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "api_name" {
  description = "API Gateway name"
  type        = string
  default     = "user-management-gateway"
}

variable "stage_name" {
  description = "API stage name"
  type        = string
  default     = "prod"
}
