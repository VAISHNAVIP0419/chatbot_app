data "aws_availability_zones" "available" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "all_worker_mgmt_ingress" {
  description       = "allow inbound traffic from eks"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  security_group_id = aws_security_group.all_worker_mgmt.id
  type              = "ingress"
  cidr_blocks = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
  ]
}

resource "aws_security_group_rule" "all_worker_mgmt_egress" {
  description       = "allow outbound traffic to anywhere"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  security_group_id = aws_security_group.all_worker_mgmt.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_iam_role" "eks_role" {
  name               = "oct-eks-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
}

data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals = [
      {
        type        = "Service"
        identifiers = ["eks.amazonaws.com"]
      }
    ]
  }
}

resource "aws_iam_policy" "eks_cluster_policy" {
  name        = "AmazonEKSClusterPolicy"
  description = "Policy to provide access to EKS clusters"
  policy      = data.aws_iam_policy_document.eks_cluster_policy.json
}

data "aws_iam_policy_document" "eks_cluster_policy" {
  statement {
    actions   = ["eks:DescribeCluster"]
    resources = ["arn:aws:eks:${var.aws_region}::cluster/"]
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attach" {
  policy_arn = aws_iam_policy.eks_cluster_policy.arn
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role" "worker_node_role" {
  name               = "oct-ec2-worker-node-role"
  assume_role_policy = data.aws_iam_policy_document.worker_node_assume_role_policy.json
}

data "aws_iam_policy_document" "worker_node_assume_role_policy" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals = [
      {
        type        = "Service"
        identifiers = ["ec2.amazonaws.com"]
      }
    ]
  }
}

resource "aws_iam_policy" "worker_node_policy" {
  name        = "AmazonEKSWorkerNodePolicy"
  description = "Policy for EKS worker node"
  policy      = data.aws_iam_policy_document.worker_node_policy.json
}

data "aws_iam_policy_document" "worker_node_policy" {
  statement {
    actions   = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "worker_node_policy_attach" {
  policy_arn = aws_iam_policy.worker_node_policy.arn
  role       = aws_iam_role.worker_node_role.name
}
