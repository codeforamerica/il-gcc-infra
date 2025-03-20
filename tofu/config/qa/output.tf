# Display commands to push the Docker image to ECR.
output "document_transfer_docker_push" {
  value = module.microservice.docker_push
}

output "database_endpoint" {
  value = module.microservice.database_endpoint
}

output "repository_arn" {
  value = module.microservice.repository_arn
}

output "repository_url" {
  value = module.microservice.repository_url
}
