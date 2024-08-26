# Document Transfer Module

This module manages the [Document Transfer Service][document-transfer] in AWS.
It launches Fargate services for the API and worker, an Aurora Serverless
database, a load balancer for ingress, and any other supporting resources.

## Usage

Add this module to your `main.tf` (or appropriate) file and configure the inputs
to match your desired configuration. For example:

```hcl
module "fargate_service" {
  source = "../../modules/document_transfer"

  domain      = "staging.service.org"
  environment = "staging"
  logging_key = module.logging.kms_key_arn
  vpc_id      = module.vpc.vpc_id

  database_capacity_min = 2
  database_capacity_max = 32

}
```

Make sure you re-run `tofu init` after adding the module to your configuration.

```bash
tofu init
tofu plan
```

## Inputs

| Name                         | Description                                                                                                                                     | Type           | Default         | Required |
|------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|----------------|-----------------|----------|
| domain                       | Domain name for service. Example: `"staging.service.org"`                                                                                       | `string`       | n/a             | yes      |
| logging_key                  | The ARN of the KMS key used for logging.                                                                                                        | `string`       | n/a             | yes      |
| vpc_id                       | The ID of the VPC in which the service is deployed.                                                                                             | `string`       | n/a             | yes      |
| environment                  | Environment for the project.                                                                                                                    | `string`       | `"development"` | no       |
| database_apply_immediately   | Immediately applies database changes rather than waiting for the next maintenance window. WARNING: This may result in a restart of the cluster! | `bool`         | `false`         | no       |
| database_capacity_max        | Maximum capacity for the database cluster in ACUs.                                                                                              | `bool`         | `false`         | no       |
| database_capacity_min        | Minimum capacity for the database cluster in ACUs.                                                                                              | `bool`         | `false`         | no       |
| database_skip_final_snapshot | Skips the final snapshot when destroying the database cluster.                                                                                  | `bool`         | `false`         | no       |
| database_snapshot            | Optional name or ARN of the snapshot to restore the cluster from. Only applicable on create.                                                    | `bool`         | `false`         | no       |
| force_delete                 | Force deletion of resources. If changing to true, be sure to apply before destroying.                                                           | `bool`         | `false`         | no       |
| ingress_cidrs                | The CIDR blocks to allow ingress from. The current VPC is allowed by default.                                                                   | `list(string)` | `[]`            | no       |
| key_recovery_period          | Number of days to recover the KMS key after deletion.                                                                                           | `number`       | `30`            | no       |
| public                       | Launch the service so that it is available on the public Internet.                                                                              | `bool`         | `false`         | no       |
| secret_recovery_period       | Recovery period for deleted secrets in days. Must be between 7 and 30, or 0 to force delete immediately.                                        | `number`       | `30`            | no       |
| service_environment          | The environment the service should operate in, if different from `environment`.                                                                 | `string`       | `""`            | no       |

## Outputs

| Name                | Description                                                                 | Type     |
|---------------------|-----------------------------------------------------------------------------|----------|
| database_endpoint   | DNS endpoint to connect to the database cluster.                            | `string` |
| database_secret_arn | ARN of the secret holding database credentials.                             | `string` |
| docker_push         | Commands to build and push a container image to the repository, if created. | `string` |
| onedrive_secret     | ARN of the secret to set OneDrive credentials into.                         | `string` |
| repository_arn      | ARN of the ECR repository, if created.                                      | `string` |
| repository_url      | URL for the container image.                                                | `string` |

[document-transfer]: https://github.com/codeforamerica/document-transfer-service
