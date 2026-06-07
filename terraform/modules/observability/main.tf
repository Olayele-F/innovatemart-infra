data "aws_region" "current" {}

# ── CloudWatch Log Group for EKS Control Plane ────────────────────────────────
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 30
  tags              = { Project = "karatu-2025-capstone" }
}

# ── IAM Role for CloudWatch Observability Addon (IRSA) ────────────────────────
resource "aws_iam_role" "cloudwatch_agent" {
  name = "${var.project_name}-cloudwatch-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"
            "${replace(var.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = { Project = "karatu-2025-capstone" }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_xray" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

# ── EKS CloudWatch Observability Addon ────────────────────────────────────────
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name                = var.cluster_name
  addon_name                  = "amazon-cloudwatch-observability"
  service_account_role_arn    = aws_iam_role.cloudwatch_agent.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [var.node_group_arn]

  tags = { Project = "karatu-2025-capstone" }
}

# ── Application log groups ─────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/containerinsights/${var.cluster_name}/application"
  retention_in_days = 30
  tags              = { Project = "karatu-2025-capstone" }
}

resource "aws_cloudwatch_log_group" "performance" {
  name              = "/aws/containerinsights/${var.cluster_name}/performance"
  retention_in_days = 14
  tags              = { Project = "karatu-2025-capstone" }
}
