output "bastion_instance_id" {
  description = "The ID of the bastion host instance."
  value       = module.bastion.instance_id
}

output "peer_ids" {
  value = module.vpc.peer_ids
}
