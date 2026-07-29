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

#### Prerequisites:
- AWS CLI
- terraform
- An aws user setup with IAM privileges

#### To setup:
```
cd terraform/prod|dev/init
aws configure --profile <your_aws_user>
terraform init
```

#### To apply changes:
```
cd terraform/prod|dev/main
terraform apply
```
