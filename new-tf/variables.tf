variable "region" {
  description = "AWS Region to deploy the resources"
  type        = string
  default     = "eu-central-1"
}

variable "aws_vpc" {
  description = "The object contains vpc related resources values"
  type        = map(string)
  default     = {}
}

variable "aws_subnets" {
  description = "The object contains subnet related resources values"
  type        = list(any)
  default     = []
}

# -- loadbalancing variables ---

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

variable "aws_dns" {
  description = "Route53 values"
  type        = map(any)
  default     = {}
}

# -- ec2 variables ---

variable "aws_sg" {
  description = "Security groups values"
  type        = map(any)
  default     = {}
}

variable "aws_ec2" {
  description = "EC2 values"
  type        = map(any)
  default     = {}
}

variable "aws_asg" {
  description = "Autoscaling Group values"
  type        = map(any)
  default     = {}
}