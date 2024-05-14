terraform {
  backend "s3" {
    bucket = "illinois-getchildcare-staging-tfstate"
    key    = "backend.tfstate"
    region = "us-east-1"
  }
}

module "backend" {
  # TODO: Create releases for tofu-modules and pin to a release.
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules/aws/backend"

  project     = "illinois-getchildcare"
  environment = "staging"
}
