data "aws_region" "current" {}

# ── bedrock-dev-view IAM User ──────────────────────────────────────────────────
resource "aws_iam_user" "dev_view" {
  name = "bedrock-dev-view"
  tags = { Project = "karatu-2025-capstone" }
}

# Console login profile (password set manually after apply — see README)
resource "aws_iam_user_login_profile" "dev_view" {
  user                    = aws_iam_user.dev_view.name
  password_reset_required = true
}

# Access keys for kubectl + grader
resource "aws_iam_access_key" "dev_view" {
  user = aws_iam_user.dev_view.name
}

# AWS Console ReadOnly
resource "aws_iam_user_policy_attachment" "readonly" {
  user       = aws_iam_user.dev_view.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# S3 PutObject on assets bucket only
resource "aws_iam_user_policy" "s3_put" {
  name = "bedrock-dev-view-s3-put"
  user = aws_iam_user.dev_view.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${var.assets_bucket_arn}/*"
      }
    ]
  })
}

# Allow user to describe the EKS cluster (needed for kubeconfig)
resource "aws_iam_user_policy" "eks_describe" {
  name = "bedrock-dev-view-eks"
  user = aws_iam_user.dev_view.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster", "eks:ListClusters"]
        Resource = "arn:aws:eks:${var.aws_region}:${var.account_id}:cluster/${var.cluster_name}"
      }
    ]
  })
}

# ── EKS Access Entry → maps IAM user to K8s view ClusterRole ──────────────────
resource "aws_eks_access_entry" "dev_view" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_user.dev_view.arn
  type          = "STANDARD"
  tags          = { Project = "karatu-2025-capstone" }
}

resource "aws_eks_access_policy_association" "dev_view_viewer" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_user.dev_view.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["retail-app"]
  }

  depends_on = [aws_eks_access_entry.dev_view]
}
