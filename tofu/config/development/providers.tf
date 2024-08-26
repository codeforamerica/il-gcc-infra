provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      project     = "illinois-getchildcare"
      environment = "staging"
      tofu        = "true"
    }
  }
}

# Create a provider alias for the microservice to set appropriate tags.
provider "aws" {
  alias = "document_transfer"
  region = "us-east-1"

  default_tags {
    tags = {
      project     = "illinois-getchildcare"
      environment = "staging"
      service     = "document-transfer"
      tofu        = "true"
    }
  }
}
