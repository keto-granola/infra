output "cloudflare_staging_access_key_id" {
  value = aws_iam_access_key.cloudflare_staging.id
}

output "cloudflare_staging_secret_access_key" {
  value     = aws_iam_access_key.cloudflare_staging.secret
  sensitive = true
}