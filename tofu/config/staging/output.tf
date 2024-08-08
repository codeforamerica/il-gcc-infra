output "peer_ids" {
  value = module.vpc.peer_ids
}

# Display commands to push the Docker image to ECR.
output "document_transfer_docker_push" {
  value = module.document_transfer.docker_push
}

output "database_endpoint" {
  value = module.database.cluster_endpoint
}
