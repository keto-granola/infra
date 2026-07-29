# Keto Granola Infra

Infrastructure for Keto Granola e-commerce platform, including:

- Running services in docker
- Provisioning with terraform

## Running services

Run:
```
make up
```

Stop:
```
make down
```

## Terraform

### Prerequisites:

- AWS CLI installed
- Terraform installed
- 3 AWS IAM users per environment dev|staging|prod (see instructions below)

### Set up IAM users
- Create each user manually on the AWS console with the following naming convention: `keto-granola-terraform-setup-<environment>`
- Attach the relevant policy to the user (see `terraform/dev|staging|prod/iam_policies.json`)
- Configure profiles locally with:

```bash
aws configure --profile <profile_name>
```

### Setup:

This is a one-time setup that creates the S3 bucket storing the Terraform state and scoped IAM users.
You should only need to re-run anything in this directory if you want to change the bucket setup or IAM permissions themselves.

1. Run:

```bash
cd terraform/dev|staging|prod/setup
terraform init
terraform apply
```

2. Save the generated credentials locally into a named AWS profile:

`<provider_name>` follows the convention `<provider>-<environment>`.

Examples:
- `cloudflare-staging`
- `s3-dev`

Run this below for every provider:

```bash
aws configure set aws_access_key_id \
  $(terraform output -raw <provider_name>_access_key_id) \
  --profile <provider_name>

aws configure set aws_secret_access_key \
  $(terraform output -raw <provider_name>_secret_access_key) \
  --profile <provider_name>

aws configure set region eu-west-2 \
  --profile <provider_name>
```

### Apply changes:
```
cd terraform/dev|staging|prod/<provider>
terraform apply
```

