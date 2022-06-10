## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output "zeppelin_home_URL" {
  value = "http://${module.oss-data-analytics.public_ip[0]}/"
}

output "grafana_home_URL" {
  value = "http://${module.oss-data-analytics.public_ip[0]}:3000/"
}

output "generated_ssh_private_key" {
  value     = module.oss-data-analytics.generated_ssh_private_key
  sensitive = true
}

output "db_user_name" {
  value = var.db_user_name
}

output "db_password" {
  value = var.db_password
}

output "mds_instance_ip" {
  value = module.mds-instance.mysql_db_system.ip_address
  sensitive = true
}