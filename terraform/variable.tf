variable "cluster_name" {
  default = "vaishnavi-eks"
}

variable "vpc_id" {
  default = "vpc-0a57822b15100e18f"
}

variable "subnet_ids" {
  default = [
    "subnet-0520c3fa6c0451794",
    "subnet-03f973d59ed405bbd",
    "subnet-055d25c03ce19fe0b"
  ]
}

