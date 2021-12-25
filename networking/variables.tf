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