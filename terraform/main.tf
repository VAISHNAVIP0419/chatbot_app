module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.4"
  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version

  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id
  enable_irsa = true

  eks_managed_node_group_defaults = {
    ami_type               = "AL2_x86_64"
    instance_types         = ["t3.medium"]
    vpc_security_group_ids = [aws_security_group.worker_sg.id]
  }

  eks_managed_node_groups = {
    default_node_group = {
      desired_size = 2
      min_size     = 1
      max_size     = 3
    }
  }

  tags = {
    "project" = "chatbot-frontend"
    "owner"   = "vaishnavi"
  }
}

resource "aws_security_group" "worker_sg" {
  name_prefix = "chatbot-worker-sg"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "ingress" {
  description       = "Allow internal traffic"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  security_group_id = aws_security_group.worker_sg.id
}

resource "aws_security_group_rule" "egress" {
  description       = "Allow all outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.worker_sg.id
}
