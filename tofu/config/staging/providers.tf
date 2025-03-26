provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      project     = "illinois-getchildcare"
      environment = "staging"
      tofu        = "true"
      application = "illinois-getchildcare-staging"
    }
  }

  ignore_tags {
    keys = ["awsApplication"]
  }
}
