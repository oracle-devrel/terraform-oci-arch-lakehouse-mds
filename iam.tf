## Copyright (c) 2022, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_identity_dynamic_group" "data_integration_dynamic_group" {
  provider       = oci.homeregion
  compartment_id = var.tenancy_ocid
  description    = "Data Integration dynamic group"
  matching_rule  = "resource.compartment.id = '${var.compartment_ocid}'"
  name           = "data-integration-dynamic-group-${random_id.tag.hex}"
}

resource "oci_identity_policy" "DataIntegrationPolicy" {
  provider       = oci.homeregion
  depends_on     = [oci_identity_dynamic_group.data_integration_dynamic_group]
  name           = "DataIntegrationPolicy-${random_id.tag.hex}"
  description    = "This policy is created for the Lakehouse Data Integration to be able to use other services and vice-versa"
  compartment_id = var.compartment_ocid
  statements = ["Allow dynamic-group data-integration-dynamic-group to read object-family in compartment id ${var.compartment_ocid}",
  "Allow dynamic-group data-integration-dynamic-group to use dis-family in compartment id ${var.compartment_ocid}",
  "Allow dynamic-group data-integration-dynamic-group to use virtual-network-family in compartment id ${var.compartment_ocid}",
  "Allow service dataintegration to use virtual-network-family in compartment id ${var.compartment_ocid}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}