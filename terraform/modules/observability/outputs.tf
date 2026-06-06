output "cloudwatch_agent_role_arn" { value = aws_iam_role.cloudwatch_agent.arn }
output "log_group_eks"             { value = aws_cloudwatch_log_group.eks.name }
output "log_group_app"             { value = aws_cloudwatch_log_group.app.name }
