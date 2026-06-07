output "rds_mysql_endpoint"      { value = aws_db_instance.mysql.address }
output "rds_postgres_endpoint"   { value = aws_db_instance.postgres.address }
output "dynamodb_carts_name"     { value = aws_dynamodb_table.carts.name }
output "mysql_secret_arn"        { value = aws_secretsmanager_secret.mysql.arn }
output "postgres_secret_arn"     { value = aws_secretsmanager_secret.postgres.arn }
