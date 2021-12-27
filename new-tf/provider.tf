terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "default"
}

terraform {
  backend "s3" {
    bucket = "d4ria-tf-state-bucket"
    key    = "my-tf.tfstate"
    region = "eu-central-1"
    profile = "default"
  }
}
