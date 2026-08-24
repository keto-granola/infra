resource "cloudflare_ruleset" "waf_custom" {
  zone_id     = var.cloudflare_zone_id
  name        = "Custom WAF Rules"
  description = "Custom firewall rules for keto granola e-commerce platform"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  # Block known bad bot user agents hitting admin routes
  rules {
    ref         = "block_admin_bots"
    action      = "block"
    expression  = "(http.request.uri.path contains \"/admin\" and cf.client.bot)"
    description = "Block bots on admin routes"
    enabled     = true
  }

  # Challenge suspicious requests with no/spoofed user agent
  rules {
    ref         = "block_suspicious_user_agent"
    action      = "managed_challenge"
    expression  = "(http.user_agent eq \"\")"
    description = "Challenge empty user agents"
    enabled     = true
  }

  # Block scanner probes for stacks we don't run (WordPress, PHP, .env, .git)
  rules {
    ref         = "block_non_existent_stack"
    action      = "block"
    expression  = "(http.request.uri.path in {\"/wp-admin\" \"/wp-login.php\" \"/.env\" \"/phpmyadmin\"} or http.request.uri.path contains \"/.git\" or http.request.uri.path contains \"/vendor/phpunit\")"
    description = "Block scanner paths for stack that doesn't exist"
    enabled     = true
  }
}

# Bot Fight Mode - free, domain-wide bot challenge (cannot be scoped to specific paths)
resource "cloudflare_bot_management" "bot_fight_mode" {
  zone_id    = var.cloudflare_zone_id
  fight_mode = true
  enable_js  = true
}

resource "cloudflare_ruleset" "waf_ratelimit" {
  zone_id     = var.cloudflare_zone_id
  name        = "Rate Limiting Rules"
  description = "Rate limiting for keto granola e-commerce platform"
  kind        = "zone"
  phase       = "http_ratelimit"

  rules {
    ref         = "rate_limit_admin"
    action      = "block"
    expression  = "(http.request.uri.path contains \"/admin\")"
    description = "Rate limit admin routes"
    enabled     = true

    ratelimit {
      characteristics     = ["cf.colo.id", "ip.src"]
      period              = 10
      requests_per_period = 10
      mitigation_timeout  = 10
    }
  }
}