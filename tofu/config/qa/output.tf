# Display commands to push the Docker image to ECR.
output "application_docker_push" {
  value = module.application.docker_push
}

output "database_endpoint" {
  value = module.application.database_endpoint
}

output "repository_arn" {
  value = module.application.repository_arn
}

output "repository_url" {
  value = module.application.repository_url
}
