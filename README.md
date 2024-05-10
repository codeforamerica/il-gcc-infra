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

### GitHub Actions

You can also run the configurations using GitHub Actions. There are two
workflows that can be called manually: [`plan.yaml`][plan] and
[`deploy.yaml`][deploy]. These workflows can be run directly from GitHub by
following their links.

Additionally, these workflows can be triggered using the
[GitHub CLI][github-cli] (where `config` is the name of a directory under
`tofu/config/`):

```bash
gh workflow run <workflow>.yaml -f environment=staging -f config=staging
```

You can then run `gh workflow list --workflow plan.yaml` to see the status of
the execution and get its id. With this id, you can watch the run and get the
logs:

```bash
gh run watch <run-id>
gh run view <run-id> --log
```

To run the workflow for a branch other than `main`, you can pass the
`--ref <branch-name>` flag.

[deploy]: https://github.com/codeforamerica/il-gcc-infra/actions/workflows/deploy.yaml
[github-cli]: https://cli.github.com/
[hcl]: https://github.com/hashicorp/hcl
[identity-center]: https://www.notion.so/cfa/AWS-Identity-Center-e8a28122b2f44595a2ef56b46788ce2c
[plan]: https://github.com/codeforamerica/il-gcc-infra/actions/workflows/plan.yaml
[terraform]: https://www.terraform.io/
[tofu]: https://opentofu.org/
