variable "cloudflare_api_token" {
  description = "Cloudflare API token, scoped to this zone"
  type        = string
  sensitive   = true
}
