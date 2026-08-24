output "target_id" {
  description = "Created Web Search Gateway target ID."
  value       = module.web_search.target_id
}

output "connector_version" {
  description = "Pinned Web Search connector version."
  value       = module.web_search.connector_version
}
