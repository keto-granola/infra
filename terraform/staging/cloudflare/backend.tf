terraform {
  backend "s3" {
    bucket = "keto-granola-staging-tfstate"
    key    = "cloudflare/state.tfstate"
    region = "eu-west-2"
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
