output "bastion_instance_id" {
  description = "The ID of the bastion host instance."
  value       = module.bastion.instance_id
}

# Display commands to push the Docker image to ECR.
output "document_transfer_docker_push" {
  value = module.microservice.docker_push
}

output "database_endpoint" {
  value = module.microservice.database_endpoint
}

output "onedrive_secret" {
  value = module.microservice.onedrive_secret.secret_arn
}

output "peer_ids" {
  value = module.vpc.peer_ids
}

output "repository_arn" {
  value = module.microservice.repository_arn
}

output "repository_url" {
  value = module.microservice.repository_url
}
