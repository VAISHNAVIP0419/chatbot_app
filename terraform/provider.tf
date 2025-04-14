provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

resource "random_string" "suffix" {
  length  = 6
  special = false
}

locals {
  cluster_name = "chatbot-eks-${random_string.suffix.result}"
}
