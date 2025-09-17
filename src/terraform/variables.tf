variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "eventbridge_source_name" {
  type        = string
  description = "Name of the Amazon EventBridge SaaS Partner Event Source to associate with an Event Bus. For example, aws.partner/example.com/1234567890/test-event-source."
}

variable "pager_duty_api_key" {
  type        = string
  description = "PagerDuty API key"
  sensitive   = true
}

variable "pager_duty_service_id" {
  type        = string
  description = "PagerDuty Service ID where incidents will be created"
}
