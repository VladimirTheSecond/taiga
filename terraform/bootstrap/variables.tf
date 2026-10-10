variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1" # Frankfurt
}

variable "domain_name" {
  description = "Apex domain of the Route 53 hosted zone"
  type        = string
  default     = "vladimirulasovets.de"
}

variable "budget_limit_usd" {
  description = "Monthly AWS budget in USD (AWS Budgets only works in USD)"
  type        = number
  default     = 23 # ~20 EUR
}

variable "budget_alert_email" {
  description = "E-mail address that receives budget alerts"
  type        = string
  default     = "ulasovetsvladimir@gmail.com"
}
