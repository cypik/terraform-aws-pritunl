output "instance_id" {
  value       = module.pritunl[*].instance_id
  description = "The instance ID."
}

output "tags" {
  value       = module.pritunl.tags
  description = "The instance tags."
}

output "public_ip" {
  value       = module.pritunl.public_ip
  description = "Public IP address assigned to the instance, if applicable."
}
