# EKS Cluster Module - Kubernetes Control Plane and Node Groups
# Creates EKS cluster with CPU, Medium GPU, and High GPU node groups

# ============================================
# EKS Cluster
# ============================================
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Networking
  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.private_subnet_ids

  # Cluster endpoint access
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Encryption
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = aws_kms_key.eks.arn
  }

  # Cluster addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # Enable IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  # Node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  tags = var.tags
}

# ============================================
# KMS Key for EKS Encryption
# ============================================
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-eks-encryption-key"
  })
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# ============================================
# CPU Node Group (Always Running)
# ============================================
resource "aws_eks_node_group" "cpu" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "${var.cluster_name}-cpu-nodes"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids

  # Instance configuration
  instance_types = [var.cpu_node_group.instance_type]
  capacity_type  = var.cpu_node_group.capacity_type
  disk_size      = var.cpu_node_group.disk_size

  # Scaling configuration
  scaling_config {
    desired_size = var.cpu_node_group.desired_size
    min_size     = var.cpu_node_group.min_size
    max_size     = var.cpu_node_group.max_size
  }

  # Update configuration
  update_config {
    max_unavailable = 1
  }

  # Node labels
  labels = {
    workload-type = "cpu"
    cost-tier     = "low"
  }

  # Node taints - none for CPU nodes (they accept all workloads)
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cpu-nodes"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
  ]
}

# ============================================
# Medium GPU Node Group (Scales to Zero)
# ============================================
resource "aws_eks_node_group" "medium_gpu" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "${var.cluster_name}-medium-gpu-nodes"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids

  # Instance configuration
  instance_types = [var.medium_gpu_node_group.instance_type]
  capacity_type  = var.medium_gpu_node_group.capacity_type
  disk_size      = var.medium_gpu_node_group.disk_size

  # Scaling configuration
  scaling_config {
    desired_size = var.medium_gpu_node_group.desired_size
    min_size     = var.medium_gpu_node_group.min_size
    max_size     = var.medium_gpu_node_group.max_size
  }

  # Update configuration
  update_config {
    max_unavailable = 1
  }

  # Node labels
  labels = {
    workload-type = "medium-gpu"
    gpu-type      = "a10g"
    cost-tier     = "medium"
  }

  # Taints - only GPU workloads can schedule here
  taint {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-medium-gpu-nodes"
    "k8s.io/cluster-autoscaler/enabled"                = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}"    = "owned"
    "k8s.io/cluster-autoscaler/node-template/label/workload-type" = "medium-gpu"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
  ]
}

# ============================================
# High GPU Node Group (Scales to Zero)
# ============================================
resource "aws_eks_node_group" "high_gpu" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "${var.cluster_name}-high-gpu-nodes"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids

  # Instance configuration
  instance_types = [var.high_gpu_node_group.instance_type]
  capacity_type  = var.high_gpu_node_group.capacity_type
  disk_size      = var.high_gpu_node_group.disk_size

  # Scaling configuration
  scaling_config {
    desired_size = var.high_gpu_node_group.desired_size
    min_size     = var.high_gpu_node_group.min_size
    max_size     = var.high_gpu_node_group.max_size
  }

  # Update configuration
  update_config {
    max_unavailable = 1
  }

  # Node labels
  labels = {
    workload-type = "high-gpu"
    gpu-type      = "a100"
    cost-tier     = "high"
  }

  # Taints - only premium GPU workloads can schedule here
  taint {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  taint {
    key    = "high-cost"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-high-gpu-nodes"
    "k8s.io/cluster-autoscaler/enabled"                = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}"    = "owned"
    "k8s.io/cluster-autoscaler/node-template/label/workload-type" = "high-gpu"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
  ]
}

# ============================================
# IAM Role for Node Groups
# ============================================
resource "aws_iam_role" "node_group" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# ============================================
# Cluster Autoscaler IAM Role (IRSA)
# ============================================
module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-cluster-autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }

  tags = var.tags
}
