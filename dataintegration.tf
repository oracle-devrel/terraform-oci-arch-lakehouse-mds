## Copyright © 2022, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_dataintegration_workspace" "lakehouse_odi_workspace" {
    provider          = oci.targetregion
    compartment_id    = var.compartment_ocid
    display_name      = "lakehouse-mds-odi-workspace"
    defined_tags      = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
    
    is_private_network_enabled = true
    subnet_id = oci_core_subnet.mds_subnet_private.id 
    vcn_id = oci_core_virtual_network.lakehouse_mds_vcn.id

}