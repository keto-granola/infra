# Keto Granola Infra

Infrastructure for Keto Granola e-commerce platform, including:

- Running services in docker
- Provisioning with terraform

## Running services

Run:
```
cd/docker/<service_name>
make up
```

Stop:
```
cd/docker/<service_name>
make down
```

## Terraform

### Prerequisites:

- AWS CLI installed
- Terraform installed
- Admin IAM user
- 3 AWS IAM users per environment dev|staging|prod (see instructions below)

### Set up admin user 
This is the only identity used for console work, debugging, and managing the x users below. It should be the only user with broad permissions. Everything else in this repo is scoped narrowly.

1. Log into the AWS console as root (this is the only time root should be used).
2. Create a `keto-granola-admin` IAM user with AWS Management Console access and a password.
3. Attach the AWS managed policy `AdministratorAccess`.
4. Enable MFA on this user.
5. Create an access key for it, then configure it locally:

```bash
aws configure --profile keto-granola-admin
```

### Set up IAM users
1. Log into the AWS console as `keto-granola-admin`.
2. Create an IAM user for each environment with the naming convention `keto-granola-terraform-setup-<environment>`
3. Attach the relevant inline policy to the user (see `terraform/dev|staging|prod/iam_policies.json`)
4. Create an access key for each user, then onfigure them locally with:

```bash
aws configure --profile keto-granola-terraform-setup-<environment>
```

5. Deactivate the admin user's access key when not actively using it since it has broad permissions:

```bash
aws iam update-access-key --user-name keto-granola-admin --access-key-id <key-id> --status Inactive --profile keto-granola-admin
```

Reactivate (--status Active) only when you need to do another admin-level task.

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

`<provider_name>` follows the convention `keto-granola-<provider>-<environment>`.

Examples:
- `keto-granola-cloudflare-staging`
- `keto-granola-s3-dev`

Run this below for every provider:

```bash
aws configure set aws_access_key_id \
  $(terraform output -raw <access_key_id_output_name>) \
  --profile <provider_name>

aws configure set aws_secret_access_key \
  $(terraform output -raw <secret_access_key_output_name>) \
  --profile <provider_name>

aws configure set region ap-southeast-2 \
  --profile <provider_name>
```

### Apply changes:
```
cd terraform/dev|staging|prod/<provider>
terraform apply
```

