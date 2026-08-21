resource "cloudflare_record" "root" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  type    = "A"
  content = var.digital_ocean_droplet_ip
  proxied = true
  ttl     = 1
}

resource "cloudflare_zone_settings_override" "settings" {
  zone_id = var.cloudflare_zone_id
  settings {
    ssl                      = "full"
    always_use_https         = "on"
    min_tls_version          = "1.2"
    automatic_https_rewrites = "on"
  }
}