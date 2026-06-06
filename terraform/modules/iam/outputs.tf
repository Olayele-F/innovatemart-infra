output "dev_user_arn"          { value = aws_iam_user.dev_view.arn }
output "dev_access_key_id"     { value = aws_iam_access_key.dev_view.id }
output "dev_secret_access_key" {
  value     = aws_iam_access_key.dev_view.secret
  sensitive = true
}
output "dev_console_password" {
  value     = aws_iam_user_login_profile.dev_view.password
  sensitive = true
}
