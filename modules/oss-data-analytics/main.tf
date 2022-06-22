## Copyright (c) 2022, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

/*terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
    }
  }
}*/

resource "tls_private_key" "public_private_key_pair" {
  algorithm = "RSA"
}

data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

data "template_file" "configure_local_security" {
  template = file("${path.module}/scripts/configure_local_security.sh")

  vars = {
  use_shared_storage = var.numberOfNodes > 1 ? tostring(true) : tostring(false)
  }
}

data "template_file" "install_mysql_shell" {
  template = file("${path.module}/scripts/install_mysql_shell.sh")

  vars = {
    mysql_version         = var.mysql_version,
    user                  = var.vm_user
  }
}

data "template_file" "create_db" {
  template = file("${path.module}/scripts/create_db.sh")
  vars = {
    admin_password = var.admin_password
    admin_username = var.admin_username
    db_user_name   = var.db_user_name
    db_password    = var.db_password
    mds_ip         = var.mds_ip
  }
}

data "template_file" "install_tools" {
  template = file("${path.module}/scripts/install_tools.sh")

  vars = {
    use_shared_storage = var.numberOfNodes > 1 ? tostring(true) : tostring(false)
    shared_working_dir = var.shared_working_dir
    mt_ip_address      = local.mt_ip_address
    user               = var.vm_user
    mysql_version      = var.mysql_version
  }
}

data "template_file" "key_script" {
  template = file("${path.module}/scripts/sshkey.tpl")
  vars = {
    ssh_public_key = tls_private_key.public_private_key_pair.public_key_openssh
  }
}

data "template_cloudinit_config" "cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "ainit.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.key_script.rendered
  }
}

locals {
  security_script     = "/home/${var.vm_user}/configure_local_security.sh"
  install_tools       = "/home/${var.vm_user}/install_tools.sh"
  create_db           = "/home/${var.vm_user}/create_db.sh"
  install_mysql_shell = "/home/${var.vm_user}/install_mysql_shell.sh"
}

data "oci_core_subnet" "analytics_subnet_ds" {
  count     = var.numberOfNodes > 1 && var.use_shared_storage ? 1 : 0
  subnet_id = var.analytics_subnet_id
}


# FSS NSG
resource "oci_core_network_security_group" "LakehouseFSSSecurityGroup" {
  count          = var.numberOfNodes > 1 && var.use_shared_storage ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "LakehouseFSSSecurityGroup"
  vcn_id         = var.vcn_id
}

# FSS NSG Ingress TCP Rules
resource "oci_core_network_security_group_security_rule" "LakehouseFSSSecurityIngressTCPGroupRules1" {
  count = var.numberOfNodes > 1 && var.use_shared_storage ? 1 : 0

  network_security_group_id = oci_core_network_security_group.LakehouseFSSSecurityGroup[0].id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = data.oci_core_subnet.analytics_subnet_ds[0].cidr_block
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      max = 111
      min = 111
    }
  }
}

# FSS NSG Ingress TCP Rules
resource "oci_core_network_security_group_security_rule" "LakehouseFSSSecurityIngressTCPGroupRules2" {
  count = var.numberOfNodes > 1 && var.use_shared_storage ? 1 : 0

  network_security_group_id = oci_core_network_security_group.LakehouseFSSSecurityGroup[0].id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = data.oci_core_subnet.analytics_subnet_ds[0].cidr_block
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      max = 2050
      min = 2048
    }
  }
}

# FSS NSG Ingress UDP Rules
resource "oci_core_network_security_group_security_rule" "LakehouseFSSSecurityIngressUDPGroupRules1" {
  count = var.numberOfNodes > 1 && var.use_shared_storage ? 1 : 0

  network_security_group_id = oci_core_network_security_group.LakehouseFSSSecurityGroup[0].id
  direction                 = "INGRESS"
  protocol                  = "17"
  source                    = data.oci_core_subnet.analytics_subnet_ds[0].cidr_block
  source_type               = "CIDR_BLOCK"

  udp_options {
    destination_port_range {
      max = 111
      min = 111
    }
  }
}

# FSS NSG Ingress UDP Rules
resource "oci_core_network_security_group_security_rule" "LakehouseFSSSecurityIngressUDPGroupRules2" {
  count = var.numberOfNodes > 1 && var.use_shared_storage ? 1 : 0

  network_security_group_id = oci_core_network_security_group.LakehouseFSSSecurityGroup[0].id
  direction                 = "INGRESS"
  protocol                  = "17"
  source                    = data.oci_core_subnet.analytics_subnet_ds[0].cidr_block
  source_type               = "CIDR_BLOCK"

  udp_options {
    destination_port_range {
      max = 2048
      min = 2048
    }
  }
}


# FSS NSG Egress TCP Rules
resource "oci_core_network_security_group_security_rule" "LakehouseFSSSecurityEgressTCPGroupRules1" {
  count = var.numberOfNodes > 1 && var.use_shared_storage ? 1 : 0

  network_security_group_id = oci_core_network_security_group.LakehouseFSSSecurityGroup[0].id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = data.oci_core_subnet.analytics_subnet_ds[0].cidr_block
  destination_type          = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      max = 111
      min = 111
    }
  }
}

# FSS NSG Egress TCP Rules
resource "oci_core_network_security_group_security_rule" "LakehouseFSSSecurityEgressTCPGroupRules2" {
  count = var.numberOfNodes > 1 && var.use_shared_storage ? 1 : 0

  network_security_group_id = oci_core_network_security_group.LakehouseFSSSecurityGroup[0].id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = data.oci_core_subnet.analytics_subnet_ds[0].cidr_block
  destination_type          = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      max = 2050
      min = 2048
    }
  }
}


# FSS NSG Egress UDP Rules
resource "oci_core_network_security_group_security_rule" "LakehouseFSSSecurityEgressUDPGroupRules1" {
  count = var.numberOfNodes > 1 && var.use_shared_storage ? 1 : 0

  network_security_group_id = oci_core_network_security_group.LakehouseFSSSecurityGroup[0].id
  direction                 = "EGRESS"
  protocol                  = "17"
  destination               = data.oci_core_subnet.analytics_subnet_ds[0].cidr_block
  destination_type          = "CIDR_BLOCK"

  udp_options {
    destination_port_range {
      max = 111
      min = 111
    }
  }

}

# Mount Target

resource "oci_file_storage_mount_target" "LakehouseMountTarget" {
  count               = var.numberOfNodes > 1 && var.use_shared_storage ? 1 : 0
  availability_domain = var.availability_domain_name == "" ? lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name") : var.availability_domain_name
  compartment_id      = var.compartment_ocid
  subnet_id           = var.fss_subnet_id
  display_name        = "LakehouseMountTarget"
  nsg_ids             = [oci_core_network_security_group.LakehouseFSSSecurityGroup[0].id]
}

data "oci_core_private_ips" "ip_mount_LakehouseMountTarget" {
  count     = var.numberOfNodes > 1 && var.use_shared_storage ? 1 : 0
  subnet_id = oci_file_storage_mount_target.LakehouseMountTarget[0].subnet_id

  filter {
    name   = "id"
    values = [oci_file_storage_mount_target.LakehouseMountTarget[0].private_ip_ids[0]]
  }
}

locals {
  mt_ip_address = var.numberOfNodes > 1 && var.use_shared_storage ? data.oci_core_private_ips.ip_mount_LakehouseMountTarget[0].private_ips[0].ip_address : ""
}


# Export Set

resource "oci_file_storage_export_set" "LakehouseExportset" {
  count           = var.numberOfNodes > 1 && var.use_shared_storage ? 1 : 0
  mount_target_id = oci_file_storage_mount_target.LakehouseMountTarget[0].id
  display_name    = "LakehouseExportset"
}

# FileSystem

resource "oci_file_storage_file_system" "LakehouseFilesystem" {
  count               = var.numberOfNodes > 1 && var.use_shared_storage ? 1 : 0
  availability_domain = var.availability_domain_name == "" ? lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name") : var.availability_domain_name
  compartment_id      = var.compartment_ocid
  display_name        = "LakehouseFilesystem"
}

# Export

resource "oci_file_storage_export" "LakehouseExport" {
  count          = var.numberOfNodes > 1 && var.use_shared_storage ? 1 : 0
  export_set_id  = oci_file_storage_mount_target.LakehouseMountTarget[0].export_set_id
  file_system_id = oci_file_storage_file_system.LakehouseFilesystem[0].id
  path           = var.shared_working_dir
}


resource "oci_core_instance" "analytics" {
  availability_domain = var.availability_domain_name == "" ? lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name") : var.availability_domain_name
  compartment_id      = var.compartment_ocid
  display_name        = "${var.label_prefix}${var.display_name}1"
  shape               = var.shape

  dynamic "shape_config" {
    for_each = local.is_flexible_node_shape ? [1] : []
    content {
      memory_in_gbs = var.flex_shape_memory
      ocpus         = var.flex_shape_ocpus
    }
  }

  create_vnic_details {
    subnet_id        = var.analytics_subnet_id
    display_name     = "${var.label_prefix}${var.display_name}1"
    assign_public_ip = false
    hostname_label   = "${var.label_prefix}${var.display_name}1"
  }

  dynamic "agent_config" {
    for_each = var.numberOfNodes > 1 ? [1] : []
    content {
      are_all_plugins_disabled = false
      is_management_disabled   = false
      is_monitoring_disabled   = false
      plugins_config {
        desired_state = "ENABLED"
        name          = "Bastion"
      }
    }
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys
    user_data           = data.template_cloudinit_config.cloud_init.rendered
  }

  source_details {
    source_id   = var.image_id
    source_type = "image"
  }

  defined_tags = var.defined_tags

  provisioner "local-exec" {
    command = "sleep 240"
  }
}

data "oci_core_vnic_attachments" "analytics_vnics" {
  depends_on          = [oci_core_instance.analytics]
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain_name == "" ? lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name") : var.availability_domain_name
  instance_id         = oci_core_instance.analytics.id
}

data "oci_core_vnic" "analytics_vnic1" {
  depends_on = [oci_core_instance.analytics]
  vnic_id    = data.oci_core_vnic_attachments.analytics_vnics.vnic_attachments[0]["vnic_id"]
}

data "oci_core_private_ips" "analytics_private_ips1" {
  depends_on = [oci_core_instance.analytics]
  vnic_id    = data.oci_core_vnic.analytics_vnic1.id
  #vnic_id   = oci_core_instance.analytics.private_ip
  subnet_id = var.analytics_subnet_id
}

resource "oci_core_public_ip" "analytics_public_ip_for_single_node" {
  depends_on     = [oci_core_instance.analytics]
  count          = var.numberOfNodes > 1 ? 0 : 1
  compartment_id = var.compartment_ocid
  display_name   = "analytics_public_ip_for_single_node"
  lifetime       = "RESERVED"
  #  private_ip_id  = var.numberOfNodes == 1 ? data.oci_core_private_ips.analytics_private_ips1.private_ips[0]["id"] : null
  private_ip_id = data.oci_core_private_ips.analytics_private_ips1.private_ips[0]["id"]
  defined_tags  = var.defined_tags
  lifecycle {
    ignore_changes = [defined_tags]
  }
}

resource "oci_core_public_ip" "analytics_public_ip_for_multi_node" {
  count          = var.numberOfNodes > 1 ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "analytics_public_ip_for_multi_node"
  lifetime       = "RESERVED"
  defined_tags   = var.defined_tags
  lifecycle {
    ignore_changes = [defined_tags]
  }
}

resource "oci_core_instance" "bastion_instance" {
  count               = (var.numberOfNodes > 1 && !var.use_bastion_service && !var.inject_bastion_server_public_ip) ? 1 : 0
  availability_domain = var.availability_domain_name == "" ? data.oci_identity_availability_domains.ADs.availability_domains[0]["name"] : var.availability_domain_name
  compartment_id      = var.compartment_ocid
  display_name        = "${var.label_prefix}BastionVM"
  shape               = var.bastion_shape

  dynamic "shape_config" {
    for_each = local.is_flexible_node_shape ? [1] : []
    content {
      memory_in_gbs = var.bastion_flex_shape_memory
      ocpus         = var.bastion_flex_shape_ocpus
    }
  }

  create_vnic_details {
    subnet_id        = var.bastion_subnet_id
    display_name     = "bastionvm"
    assign_public_ip = true
  }

  source_details {
    source_id   = var.bastion_image_id
    source_type = "image"
  }

  defined_tags = var.defined_tags

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys
    user_data           = data.template_cloudinit_config.cloud_init.rendered
  }
}


resource "oci_bastion_bastion" "bastion-service" {
  count            = (var.numberOfNodes > 1 && var.use_bastion_service && !var.inject_bastion_service_id) ? 1 : 0
  bastion_type     = "STANDARD"
  compartment_id   = var.compartment_ocid
  target_subnet_id = var.analytics_subnet_id
  client_cidr_block_allow_list = ["0.0.0.0/0"]
  name                         = "BastionService4analytics"
  max_session_ttl_in_seconds   = 10800
}

data "oci_computeinstanceagent_instance_agent_plugins" "analytics_agent_plugin_bastion" {
  count            = var.numberOfNodes > 1 && var.use_bastion_service ? 1 : 0
  compartment_id   = var.compartment_ocid
  instanceagent_id = oci_core_instance.analytics.id
  name             = "Bastion"
  status           = "RUNNING"
}

resource "time_sleep" "analytics_agent_checker" {
  depends_on      = [oci_core_instance.analytics]
  count           = var.numberOfNodes > 1 && var.use_bastion_service ? 1 : 0
  create_duration = "60s"

  triggers = {
    changed_time_stamp = length(data.oci_computeinstanceagent_instance_agent_plugins.analytics_agent_plugin_bastion) != 0 ? 0 : timestamp()
    instance_ocid  = oci_core_instance.analytics.id
    private_ip     = oci_core_instance.analytics.private_ip
  }
}

resource "oci_bastion_session" "ssh_via_bastion_service" {
  depends_on = [oci_core_instance.analytics]
  count      = var.numberOfNodes > 1 && var.use_bastion_service ? 1 : 0
  bastion_id = var.bastion_service_id == "" ? oci_bastion_bastion.bastion-service[0].id : var.bastion_service_id 

  key_details {
    public_key_content = tls_private_key.public_private_key_pair.public_key_openssh
  }

  target_resource_details {
    session_type                               = "MANAGED_SSH"
    target_resource_id                         = time_sleep.analytics_agent_checker[count.index].triggers["instance_ocid"]
    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = 22
    target_resource_private_ip_address         = time_sleep.analytics_agent_checker[count.index].triggers["private_ip"]
  }

  display_name           = "ssh_via_bastion_service_to_analytics1"
  key_type               = "PUB"
  session_ttl_in_seconds = 10800
}

resource "null_resource" "analytics_provisioner_without_bastion" {
  count      = var.numberOfNodes > 1 ? 0 : 1
  depends_on = [oci_core_instance.analytics, oci_core_public_ip.analytics_public_ip_for_single_node]

  provisioner "file" {
    content     = data.template_file.configure_local_security.rendered
    destination = local.security_script

    connection {
      type        = "ssh"
      host        = oci_core_public_ip.analytics_public_ip_for_single_node[0].ip_address
      agent       = false
      timeout     = "5m"
      user        = var.vm_user
      private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

  provisioner "file" {
    content     = data.template_file.install_tools.rendered
    destination = local.install_tools

    connection {
      type        = "ssh"
      host        = oci_core_public_ip.analytics_public_ip_for_single_node[0].ip_address
      agent       = false
      timeout     = "5m"
      user        = var.vm_user
      private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

  provisioner "file" {
    content     = data.template_file.install_mysql_shell.rendered
    destination = local.install_mysql_shell

    connection {
      type        = "ssh"
      host        = oci_core_public_ip.analytics_public_ip_for_single_node[0].ip_address
      agent       = false
      timeout     = "5m"
      user        = var.vm_user
      private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

  provisioner "file" {
    content     = data.template_file.create_db.rendered
    destination = local.create_db

    connection {
      type        = "ssh"
      host        = oci_core_public_ip.analytics_public_ip_for_single_node[0].ip_address
      agent       = false
      timeout     = "5m"
      user        = var.vm_user
      private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = oci_core_public_ip.analytics_public_ip_for_single_node[0].ip_address
      agent       = false
      timeout     = "5m"
      user        = var.vm_user
      private_key = tls_private_key.public_private_key_pair.private_key_pem
    }

    inline = [
      "chmod +x ${local.security_script}",
      "sudo ${local.security_script}",
      "chmod +x ${local.install_tools}",
      "sudo ${local.install_tools}",
      "chmod +x ${local.install_mysql_shell}",
      "sudo ${local.install_mysql_shell}",
      "chmod +x ${local.create_db}",
      "sudo ${local.create_db}"
    ]

  }

}

resource "null_resource" "analytics_provisioner_with_bastion" {
  count = (var.numberOfNodes > 1 && !var.inject_bastion_server_public_ip) ? 1 : 0
  depends_on = [oci_core_instance.analytics,
    oci_core_network_security_group.LakehouseFSSSecurityGroup,
    oci_core_network_security_group_security_rule.LakehouseFSSSecurityIngressTCPGroupRules1,
    oci_core_network_security_group_security_rule.LakehouseFSSSecurityIngressTCPGroupRules2,
    oci_core_network_security_group_security_rule.LakehouseFSSSecurityIngressUDPGroupRules1,
    oci_core_network_security_group_security_rule.LakehouseFSSSecurityIngressUDPGroupRules2,
    oci_core_network_security_group_security_rule.LakehouseFSSSecurityEgressTCPGroupRules1,
    oci_core_network_security_group_security_rule.LakehouseFSSSecurityEgressTCPGroupRules2,
    oci_core_network_security_group_security_rule.LakehouseFSSSecurityEgressUDPGroupRules1,
    oci_file_storage_export.LakehouseExport,
    oci_file_storage_file_system.LakehouseFilesystem,
    oci_file_storage_export_set.LakehouseExportset,
  oci_file_storage_mount_target.LakehouseMountTarget]

  provisioner "file" {
    content     = data.template_file.configure_local_security.rendered
    destination = local.security_script

    connection {
      type                = "ssh"
      host                = data.oci_core_vnic.analytics_vnic1.private_ip_address
      agent               = false
      timeout             = "5m"
      user                = var.vm_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = var.use_bastion_service ? "host.bastion.${var.bastion_service_region}.oci.oraclecloud.com" : oci_core_instance.bastion_instance[0].public_ip
      bastion_user        = var.use_bastion_service ? oci_bastion_session.ssh_via_bastion_service[0].id : var.vm_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

  provisioner "file" {
    content     = data.template_file.install_tools.rendered
    destination = local.install_tools

    connection {
      type                = "ssh"
      host                = data.oci_core_vnic.analytics_vnic1.private_ip_address
      agent               = false
      timeout             = "5m"
      user                = var.vm_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = var.use_bastion_service ? "host.bastion.${var.bastion_service_region}.oci.oraclecloud.com" : oci_core_instance.bastion_instance[0].public_ip
      bastion_user        = var.use_bastion_service ? oci_bastion_session.ssh_via_bastion_service[0].id : var.vm_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

provisioner "file" {
    content     = data.template_file.install_mysql_shell.rendered
    destination = local.install_mysql_shell

    connection {
      type                = "ssh"
      host                = data.oci_core_vnic.analytics_vnic1.private_ip_address
      agent               = false
      timeout             = "5m"
      user                = var.vm_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = var.use_bastion_service ? "host.bastion.${var.bastion_service_region}.oci.oraclecloud.com" : oci_core_instance.bastion_instance[0].public_ip
      bastion_user        = var.use_bastion_service ? oci_bastion_session.ssh_via_bastion_service[0].id : var.vm_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

  provisioner "file" {
    content     = data.template_file.create_db.rendered
    destination = local.create_db

    connection {
      type                = "ssh"
      host                = data.oci_core_vnic.analytics_vnic1.private_ip_address
      agent               = false
      timeout             = "5m"
      user                = var.vm_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = var.use_bastion_service ? "host.bastion.${var.bastion_service_region}.oci.oraclecloud.com" : oci_core_instance.bastion_instance[0].public_ip
      bastion_user        = var.use_bastion_service ? oci_bastion_session.ssh_via_bastion_service[0].id : var.vm_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      host                = data.oci_core_vnic.analytics_vnic1.private_ip_address
      agent               = false
      timeout             = "5m"
      user                = var.vm_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = var.use_bastion_service ? "host.bastion.${var.bastion_service_region}.oci.oraclecloud.com" : oci_core_instance.bastion_instance[0].public_ip
      bastion_user        = var.use_bastion_service ? oci_bastion_session.ssh_via_bastion_service[0].id : var.vm_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }

    inline = [
      "chmod +x ${local.security_script}",
      "sudo ${local.security_script}",
      "chmod +x ${local.install_tools}",
      "sudo ${local.install_tools}",
      "chmod +x ${local.install_mysql_shell}",
      "sudo ${local.install_mysql_shell}",
      "chmod +x ${local.create_db}",
      "sudo ${local.create_db}"
    ]

  }

}

resource "null_resource" "analytics_provisioner_with_injected_bastion_server_public_ip" {
  count = (var.numberOfNodes > 1 && var.inject_bastion_server_public_ip) ? 1 : 0
  depends_on = [oci_core_instance.analytics,
    oci_core_network_security_group.LakehouseFSSSecurityGroup,
    oci_core_network_security_group_security_rule.LakehouseFSSSecurityIngressTCPGroupRules1,
    oci_core_network_security_group_security_rule.LakehouseFSSSecurityIngressTCPGroupRules2,
    oci_core_network_security_group_security_rule.LakehouseFSSSecurityIngressUDPGroupRules1,
    oci_core_network_security_group_security_rule.LakehouseFSSSecurityIngressUDPGroupRules2,
    oci_core_network_security_group_security_rule.LakehouseFSSSecurityEgressTCPGroupRules1,
    oci_core_network_security_group_security_rule.LakehouseFSSSecurityEgressTCPGroupRules2,
    oci_core_network_security_group_security_rule.LakehouseFSSSecurityEgressUDPGroupRules1,
    oci_file_storage_export.LakehouseExport,
    oci_file_storage_file_system.LakehouseFilesystem,
    oci_file_storage_export_set.LakehouseExportset,
  oci_file_storage_mount_target.LakehouseMountTarget]

  provisioner "file" {
    content     = data.template_file.configure_local_security.rendered
    destination = local.security_script

    connection {
      type                = "ssh"
      host                = data.oci_core_vnic.analytics_vnic1.private_ip_address
      agent               = false
      timeout             = "5m"
      user                = var.vm_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = var.bastion_server_public_ip
      bastion_user        = var.vm_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

  provisioner "file" {
    content     = data.template_file.install_tools.rendered
    destination = local.install_tools

    connection {
      type                = "ssh"
      host                = data.oci_core_vnic.analytics_vnic1.private_ip_address
      agent               = false
      timeout             = "5m"
      user                = var.vm_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = var.bastion_server_public_ip
      bastion_user        = var.vm_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

  provisioner "file" {
    content     = data.template_file.install_mysql_shell.rendered
    destination = local.install_mysql_shell

    connection {
      type                = "ssh"
      host                = data.oci_core_vnic.analytics_vnic1.private_ip_address
      agent               = false
      timeout             = "5m"
      user                = var.vm_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = var.bastion_server_public_ip
      bastion_user        = var.vm_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

    provisioner "file" {
    content     = data.template_file.create_db.rendered
    destination = local.create_db

    connection {
      type                = "ssh"
      host                = data.oci_core_vnic.analytics_vnic1.private_ip_address
      agent               = false
      timeout             = "5m"
      user                = var.vm_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = var.bastion_server_public_ip
      bastion_user        = var.vm_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      host                = data.oci_core_vnic.analytics_vnic1.private_ip_address
      agent               = false
      timeout             = "5m"
      user                = var.vm_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = var.bastion_server_public_ip
      bastion_user        = var.vm_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }

    inline = [
      "chmod +x ${local.security_script}",
      "sudo ${local.security_script}",
      "chmod +x ${local.install_tools}",
      "sudo ${local.install_tools}",
      "chmod +x ${local.install_mysql_shell}",
      "sudo ${local.install_mysql_shell}",
      "chmod +x ${local.create_db}",
      "sudo ${local.create_db}"
    ]

  }

}

# Create analyticsImage

resource "oci_core_image" "analytics_instance_image" {
  count          = var.numberOfNodes > 1 ? 1 : 0
  depends_on     = [null_resource.analytics_provisioner_with_bastion, null_resource.analytics_provisioner_with_injected_bastion_server_public_ip]
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.analytics.id
  display_name   = "analytics_instance_image"
  defined_tags   = var.defined_tags
}

resource "oci_core_instance" "analytics_from_image" {
  count               = var.numberOfNodes > 1 ? var.numberOfNodes - 1 : 0
  availability_domain = var.availability_domain_name == "" ? lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name") : var.availability_domain_name
  compartment_id      = var.compartment_ocid
  display_name        = "${var.label_prefix}${var.display_name}${count.index + 2}"
  shape               = var.shape

  dynamic "shape_config" {
    for_each = local.is_flexible_node_shape ? [1] : []
    content {
      memory_in_gbs = var.flex_shape_memory
      ocpus         = var.flex_shape_ocpus
    }
  }

  create_vnic_details {
    subnet_id        = var.analytics_subnet_id
    display_name     = "${var.label_prefix}${var.display_name}${count.index + 2}"
    assign_public_ip = false
    hostname_label   = "${var.label_prefix}${var.display_name}${count.index + 2}"
  }

  dynamic "agent_config" {
    for_each = var.numberOfNodes > 1 ? [1] : []
    content {
      are_all_plugins_disabled = false
      is_management_disabled   = false
      is_monitoring_disabled   = false
      plugins_config {
        desired_state = "ENABLED"
        name          = "Bastion"
      }
    }
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys
  }

  source_details {
    source_id   = oci_core_image.analytics_instance_image[0].id
    source_type = "image"
  }

  defined_tags = var.defined_tags

  provisioner "local-exec" {
    command = "sleep 240"
  }
}

data "oci_computeinstanceagent_instance_agent_plugins" "analytics2plus_agent_plugin_bastion" {
  count            = var.numberOfNodes > 1 && var.use_bastion_service ? var.numberOfNodes - 1 : 0
  compartment_id   = var.compartment_ocid
  instanceagent_id = oci_core_instance.analytics_from_image[count.index].id
  name             = "Bastion"
  status           = "RUNNING"
}

resource "time_sleep" "analytics2plus_agent_checker" {
  depends_on      = [oci_core_instance.analytics_from_image]
  count           = var.numberOfNodes > 1 && var.use_bastion_service ? var.numberOfNodes - 1 : 0
  create_duration = "60s"

  triggers = {
    changed_time_stamp = length(data.oci_computeinstanceagent_instance_agent_plugins.analytics2plus_agent_plugin_bastion) != 0 ? 0 : timestamp()
    instance_ocid  = oci_core_instance.analytics_from_image[count.index].id
    private_ip     = oci_core_instance.analytics_from_image[count.index].private_ip
  }
}

resource "oci_bastion_session" "ssh_via_bastion_service2plus" {
  depends_on = [oci_core_instance.analytics]
  count      = var.numberOfNodes > 1 && var.use_bastion_service ? var.numberOfNodes - 1 : 0
  bastion_id = var.bastion_service_id == "" ? oci_bastion_bastion.bastion-service[0].id : var.bastion_service_id 

  key_details {
    public_key_content = tls_private_key.public_private_key_pair.public_key_openssh
  }

  target_resource_details {
    session_type                               = "MANAGED_SSH"
    target_resource_id                         = time_sleep.analytics2plus_agent_checker[count.index].triggers["instance_ocid"]
    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = 22
    target_resource_private_ip_address         = time_sleep.analytics2plus_agent_checker[count.index].triggers["private_ip"]
  }

  display_name           = "ssh_via_bastion_service_to_analytics${count.index + 2}"
  key_type               = "PUB"
  session_ttl_in_seconds = 10800
}

resource "oci_load_balancer" "lb01" {
  count = var.numberOfNodes > 1 ? 1 : 0
  shape = var.lb_shape

  dynamic "shape_details" {
    for_each = local.is_flexible_lb_shape ? [1] : []
    content {
      minimum_bandwidth_in_mbps = var.flex_lb_min_shape
      maximum_bandwidth_in_mbps = var.flex_lb_max_shape
    }
  }

  dynamic "reserved_ips" {
    for_each = var.numberOfNodes > 1 ? [1] : []
    content {
      id = oci_core_public_ip.analytics_public_ip_for_multi_node[0].id
    }
  }
  compartment_id = var.compartment_ocid

  subnet_ids = [
    var.lb_subnet_id,
  ]

  display_name = "analytics_lb"
  defined_tags = var.defined_tags
}

resource "oci_load_balancer_backend_set" "lb_bes_zeppelin" {
  count            = var.numberOfNodes > 1 ? 1 : 0
  name             = "zeppelinLBBackendSet"
  load_balancer_id = oci_load_balancer.lb01[count.index].id
  policy           = "ROUND_ROBIN"

  health_checker {
    port                = "80"
    protocol            = "HTTP"
    response_body_regex = ".*"
    url_path            = "/"
    interval_ms         = "10000"
    return_code         = "200"
    timeout_in_millis   = "3000"
    retries             = "3"
  }
}

resource "oci_load_balancer_listener" "lb_listener_zeppelin" {
  count                    = var.numberOfNodes > 1 ? 1 : 0
  load_balancer_id         = oci_load_balancer.lb01[count.index].id
  name                     = "zeppelin"
  default_backend_set_name = oci_load_balancer_backend_set.lb_bes_zeppelin[count.index].name
  port                     = 80
  protocol                 = "HTTP"

}

resource "oci_load_balancer_backend" "lb_be_zeppelin1" {
  count            = var.numberOfNodes > 1 ? 1 : 0
  load_balancer_id = oci_load_balancer.lb01[0].id
  backendset_name  = oci_load_balancer_backend_set.lb_bes_zeppelin[0].name
  ip_address       = oci_core_instance.analytics.private_ip
  port             = 80
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "oci_load_balancer_backend" "lb_be_zeppelin2plus" {
  count            = var.numberOfNodes > 1 ? var.numberOfNodes - 1 : 0
  load_balancer_id = oci_load_balancer.lb01[0].id
  backendset_name  = oci_load_balancer_backend_set.lb_bes_zeppelin[0].name
  ip_address       = oci_core_instance.analytics_from_image[count.index].private_ip
  port             = 80
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "oci_load_balancer_backend_set" "lb_bes_grafana" {
  count            = var.numberOfNodes > 1 ? 1 : 0
  name             = "grafanaLBBackendSet"
  load_balancer_id = oci_load_balancer.lb01[count.index].id
  policy           = "ROUND_ROBIN"

  health_checker {
    port                = "3000"
    protocol            = "HTTP"
    response_body_regex = ".*"
    url_path            = "/api/health"
    interval_ms         = "10000"
    return_code         = "200"
    timeout_in_millis   = "3000"
    retries             = "3"
  }
}

resource "oci_load_balancer_listener" "lb_listener_grafana" {
  count                    = var.numberOfNodes > 1 ? 1 : 0
  load_balancer_id         = oci_load_balancer.lb01[count.index].id
  name                     = "grafana"
  default_backend_set_name = oci_load_balancer_backend_set.lb_bes_grafana[count.index].name
  port                     = 3000
  protocol                 = "HTTP"

}

resource "oci_load_balancer_backend" "lb_be_grafana1" {
  count            = var.numberOfNodes > 1 ? 1 : 0
  load_balancer_id = oci_load_balancer.lb01[0].id
  backendset_name  = oci_load_balancer_backend_set.lb_bes_grafana[0].name
  ip_address       = oci_core_instance.analytics.private_ip
  port             = 3000
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "oci_load_balancer_backend" "lb_be_grafana2plus" {
  count            = var.numberOfNodes > 1 ? var.numberOfNodes - 1 : 0
  load_balancer_id = oci_load_balancer.lb01[0].id
  backendset_name  = oci_load_balancer_backend_set.lb_bes_grafana[0].name
  ip_address       = oci_core_instance.analytics_from_image[count.index].private_ip
  port             = 3000
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}