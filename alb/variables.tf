variable "region" {
  description = "AWS Region to deploy the resources"
  type        = string
  default     = "eu-central-1"
}

variable "aws_sg" {
  description = "Security groups values"
  type        = map(any)
  default     = {}
}

variable "aws_lb" {
  description = "Loadbalancer values"
  type        = map(any)
  default     = {}
}

variable "aws_lb_tg" {
  description = "Loadbalancer Target Group values"
  type        = map(any)
  default     = {}
}

variable "aws_lb_tg_health_check" {
  description = "Loadbalancer Target Group health check values"
  type        = map(any)
  default     = {}
}



