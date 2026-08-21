resource "cloudflare_record" "root" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  type    = "A"
  content = var.digital_ocean_droplet_ip
  proxied = true
  ttl     = 1
}