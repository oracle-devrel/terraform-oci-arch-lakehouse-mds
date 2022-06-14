## Copyright © 2022, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

locals {
    namespace = data.oci_objectstorage_namespace.os_namespace.namespace
}

resource "oci_objectstorage_bucket" "data-lake" {
    compartment_id = var.compartment_ocid
    name = "${var.data_lake_bucket_name}-${random_id.tag.hex}"
    namespace = local.namespace
    access_type = var.data_lake_bucket_access_type
    storage_tier = var.data_lake_bucket_storage_tier
    defined_tags = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

