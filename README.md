# innovatemart-infra

Terraform infrastructure for Project Bedrock — EKS cluster, VPC, RDS, DynamoDB, S3, Lambda, IAM.

## GitHub Secrets Required

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM CI/CD user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM CI/CD user secret key |
| `STUDENT_ID` | Your student ID (appended to S3 bucket name) |
| `DB_PASSWORD_MYSQL` | RDS MySQL master password |
| `DB_PASSWORD_POSTGRES` | RDS PostgreSQL master password |

## Deployment Steps

### 1. Bootstrap remote state (run once)
```powershell
cd innovatemart-infra
pwsh scripts/bootstrap-state.ps1
```

### 2. Copy and edit tfvars
```powershell
cd terraform
Copy-Item terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars
```
Set `student_id` to your actual student ID.

### 3. Set environment variables
```powershell
$env:TF_VAR_db_password_mysql    = "YourMySQLPassword123!"
$env:TF_VAR_db_password_postgres = "YourPostgresPassword123!"
$env:TF_VAR_student_id           = "your-student-id"
```

### 4. Deploy
```powershell
terraform init
terraform plan -var="student_id=$env:TF_VAR_student_id" -var="db_password_mysql=$env:TF_VAR_db_password_mysql" -var="db_password_postgres=$env:TF_VAR_db_password_postgres"
terraform apply -var="student_id=$env:TF_VAR_student_id" -var="db_password_mysql=$env:TF_VAR_db_password_mysql" -var="db_password_postgres=$env:TF_VAR_db_password_postgres"
```

### 5. Generate grading file
```powershell
terraform output -json > ../grading.json
```

## Required Outputs (grading script)
- `cluster_endpoint`
- `cluster_name`
- `region`
- `vpc_id`
- `assets_bucket_name`
