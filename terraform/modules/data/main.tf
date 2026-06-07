data "aws_region" "current" {}

# ── DB Subnet Group ────────────────────────────────────────────────────────────
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags = {
    Name    = "${var.project_name}-db-subnet-group"
    Project = "karatu-2025-capstone"
  }
}

# ── RDS Security Group — allow from EKS nodes only ────────────────────────────
resource "aws_security_group" "rds_mysql" {
  name        = "${var.project_name}-rds-mysql-sg"
  description = "Allow MySQL from EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.eks_node_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-rds-mysql-sg"
    Project = "karatu-2025-capstone"
  }
}

resource "aws_security_group" "rds_postgres" {
  name        = "${var.project_name}-rds-postgres-sg"
  description = "Allow PostgreSQL from EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_node_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-rds-postgres-sg"
    Project = "karatu-2025-capstone"
  }
}

# ── RDS MySQL ──────────────────────────────────────────────────────────────────
resource "aws_db_instance" "mysql" {
  identifier             = "${var.project_name}-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "retailstore"
  username               = "admin"
  password               = var.db_password_mysql
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_mysql.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false
  storage_encrypted      = true

  tags = {
    Name    = "${var.project_name}-mysql"
    Project = "karatu-2025-capstone"
  }
}

# ── RDS PostgreSQL ─────────────────────────────────────────────────────────────
resource "aws_db_instance" "postgres" {
  identifier             = "${var.project_name}-postgres"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "retailstore"
  username               = "dbadmin"
  password               = var.db_password_postgres
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_postgres.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false
  storage_encrypted      = true

  tags = {
    Name    = "${var.project_name}-postgres"
    Project = "karatu-2025-capstone"
  }
}

# ── DynamoDB Tables ────────────────────────────────────────────────────────────
resource "aws_dynamodb_table" "carts" {
  name         = "${var.project_name}-carts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name    = "${var.project_name}-carts"
    Project = "karatu-2025-capstone"
  }
}

# ── Secrets Manager — store DB credentials ────────────────────────────────────
resource "aws_secretsmanager_secret" "mysql" {
  name                    = "${var.project_name}/mysql"
  recovery_window_in_days = 0
  tags                    = { Project = "karatu-2025-capstone" }
}

resource "aws_secretsmanager_secret_version" "mysql" {
  secret_id = aws_secretsmanager_secret.mysql.id
  secret_string = jsonencode({
    username = "admin"
    password = var.db_password_mysql
    host     = aws_db_instance.mysql.address
    port     = 3306
    dbname   = "retailstore"
  })
}

resource "aws_secretsmanager_secret" "postgres" {
  name                    = "${var.project_name}/postgres"
  recovery_window_in_days = 0
  tags                    = { Project = "karatu-2025-capstone" }
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id = aws_secretsmanager_secret.postgres.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = var.db_password_postgres
    host     = aws_db_instance.postgres.address
    port     = 5432
    dbname   = "retailstore"
  })
}
