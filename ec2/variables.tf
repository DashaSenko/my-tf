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

variable "aws_ec2" {
  description = "EC2 values"
  type        = map(any)
  default     = {}
}