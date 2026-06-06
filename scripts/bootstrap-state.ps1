#!/usr/bin/env pwsh
# bootstrap-state.ps1
# Run ONCE before terraform init to create the S3 remote state bucket.

param(
  [string]$BucketName = "project-bedrock-tfstate",
  [string]$Region     = "us-east-1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Log { param([string]$msg) Write-Host "[$([DateTime]::Now.ToString('HH:mm:ss'))] $msg" -ForegroundColor Cyan }

# Create bucket
Log "Creating state bucket: $BucketName"
try {
  aws s3api create-bucket --bucket $BucketName --region $Region
  Log "Bucket created."
} catch {
  Log "Bucket may already exist — continuing."
}

# Enable versioning
Log "Enabling versioning..."
aws s3api put-bucket-versioning `
  --bucket $BucketName `
  --versioning-configuration Status=Enabled

# Block public access
Log "Blocking public access..."
aws s3api put-public-access-block `
  --bucket $BucketName `
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Enable encryption
Log "Enabling encryption..."
$encryptionConfig = '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-bucket-encryption `
  --bucket $BucketName `
  --server-side-encryption-configuration $encryptionConfig

Log "State bucket ready: $BucketName"
Log "Now run: terraform init"
