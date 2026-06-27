output "vm_name" {
  description = "Name of the provisioned VM."
  value       = google_compute_instance.vm.name
}

output "vm_external_ip" {
  description = "Public IP address of the VM."
  value       = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM."
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "dns_zone_name_servers" {
  description = "Name servers for the managed zone. Set these at your domain registrar."
  value       = google_dns_managed_zone.zone.name_servers
}

output "dns_fqdn" {
  description = "Fully qualified domain name mapped to the VM."
  value       = trimsuffix(google_dns_record_set.a_record.name, ".")
}
