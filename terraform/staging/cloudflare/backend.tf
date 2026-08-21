terraform {
  backend "s3" {
    bucket = "keto-granola-tfstate-staging"
    key    = "cloudflare/state.tfstate"
    region = "ap-southeast-2"
    profile = "keto-granola-cloudflare-staging"
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
