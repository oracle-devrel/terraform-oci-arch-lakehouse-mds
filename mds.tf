## Copyright (c) 2022, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

module "mds-instance" {
    source = "github.com/oracle-devrel/terraform-oci-cloudbricks-mysql-database?ref=v1.0.4.1"
    #providers                                       = { oci = oci.targetregion }
    tenancy_ocid                                    = var.tenancy_ocid
    region                                          = var.region
    mysql_instance_compartment_ocid                 = var.compartment_ocid
    mysql_network_compartment_ocid                  = var.compartment_ocid
    subnet_id                                       = oci_core_subnet.mds_subnet_private.id
    mysql_db_system_admin_username                  = var.admin_username
    mysql_db_system_admin_password                  = var.admin_password
    mysql_db_system_availability_domain             = var.availability_domain_name == "" ? lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name") : var.availability_domain_name
    mysql_shape_name                                = var.mysql_shape
    mysql_db_system_data_storage_size_in_gb         = var.mysql_db_system_data_storage_size_in_gb
    mysql_db_system_defined_tags                    = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
    mysql_db_system_description                     = var.mysql_db_system_description
    mysql_db_system_display_name                    = var.mysql_db_system_display_name
    mysql_db_system_fault_domain                    = var.mysql_db_system_fault_domain
    mysql_db_system_hostname_label                  = var.mysql_db_system_hostname_label
    mysql_db_system_is_highly_available             = var.mysql_is_highly_available
    mysql_db_system_maintenance_window_start_time   = var.mysql_db_system_maintenance_window_start_time
}