# Illinois GetChildCare Infrastructure

Infrastructure configuration for the Illinois GetChildCare backend.

## Requirements

The configurations are written in [HCL] and support both [OpenTofu][tofu] and
the equivalent version of [Terraform].

## Usage

### Local

To run the configurations locally, you will need to have AWS credentials loaded
from [Identity Center][identity-center], and installed OpenTofu.

Navigate to the configuration you would like to plan or apply, then run the
plan command to see what changes will be made:

```bash
cd tofu/config/staging # Replace with the appropriate configuration
tofu init
tofu plan -o tfplan.out
```

Review the plan output. If the changes are acceptable, apply the changes:

```bash
tofu apply tfplan.out
```

[hcl]: https://github.com/hashicorp/hcl
[identity-center]: https://www.notion.so/cfa/AWS-Identity-Center-e8a28122b2f44595a2ef56b46788ce2c
[terraform]: https://www.terraform.io/
[tofu]: https://opentofu.org/
