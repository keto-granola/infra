output "cloudflare_access_key_id_staging" {
  value = aws_iam_access_key.cloudflare_staging.id
  sensitive = true
}

output "cloudflare_secret_access_key_staging" {
  value     = aws_iam_access_key.cloudflare_staging.secret
  sensitive = true
}