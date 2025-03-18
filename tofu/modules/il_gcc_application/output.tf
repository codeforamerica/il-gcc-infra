output "database_endpoint" {
  value = module.database.cluster_endpoint
}

output "database_secret_arn" {
  value = module.database.secret_arn
}

output "docker_push" {
  value = module.service.docker_push
}


output "repository_arn" {
  value = module.service.repository_arn
}

output "repository_url" {
  value = module.service.repository_url
}
