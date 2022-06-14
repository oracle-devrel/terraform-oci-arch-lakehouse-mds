## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output "db_user_name" {
  value = var.db_user_name
}

output "public_ip" {
  value = var.numberOfNodes > 1 ? oci_core_public_ip.analytics_public_ip_for_multi_node.*.ip_address : oci_core_public_ip.analytics_public_ip_for_single_node.*.ip_address
}

output "generated_ssh_private_key" {
  value     = tls_private_key.public_private_key_pair.private_key_pem
  sensitive = true
}

output "generated_ssh_public_key" {
  value     = tls_private_key.public_private_key_pair.public_key_openssh
  sensitive = true
}

output "bastion_ssh_metadata" {
  value = concat(oci_bastion_session.ssh_via_bastion_service.*.ssh_metadata, oci_bastion_session.ssh_via_bastion_service2plus.*.ssh_metadata)
}