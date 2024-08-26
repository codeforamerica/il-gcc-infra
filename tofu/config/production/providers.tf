provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      project     = "illinois-getchildcare"
      environment = "production"
      tofu        = "true"
    }
  }
}
