variable "cloudflare_api_token" {
  description = "Cloudflare API token, scoped to this zone"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  sensitive   = true
}

variable "digital_ocean_droplet_ip" {
  description = "Digital Ocean droplet ip address"
  type        = string
  sensitive   = true
}