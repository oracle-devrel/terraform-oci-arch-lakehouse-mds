# terraform-oci-arch-drupal

This is Terraform module that deploys [Drupal](https://www.drupal.org/) on [Oracle Cloud Infrastructure (OCI)](https://cloud.oracle.com/en_US/cloud-infrastructure).

## About
Drupal is one of the most popular content management systems (CMS) available. It is free and open-source, released under the GNU Public License.

Drupal is based on the LAMP stack and provides users and enterprises a scalable and robust architecture, low implementation and maintenance efforts, as well as a large community-led knowledge base. Its setup and usage does not require advanced technical skills. It provides the infrastructure for websites worldwide—ranging from personal blogs to corporate, political, and government sites. It is very extensible and modular, making it useful in a large variety of scenarios.

## Prerequisites
1. Download and install Terraform (v1.0 or later)
2. Download and install the OCI Terraform Provider (v4.4.0 or later)
3. Export OCI credentials. (this refer to the https://github.com/oracle/terraform-provider-oci )


## What's a Module?
A Module is a canonical, reusable, best-practices definition for how to run a single piece of infrastructure, such as a database or server cluster. Each Module is created using Terraform, and includes automated tests, examples, and documentation. It is maintained both by the open source community and companies that provide commercial support.
Instead of figuring out the details of how to run a piece of infrastructure from scratch, you can reuse existing code that has been proven in production. And instead of maintaining all that infrastructure code yourself, you can leverage the work of the Module community to pick up infrastructure improvements through a version number bump.

## How to use this Module
This Module has the following folder structure:
* [root](): This folder contains a root module.
* [examples](examples): This folder contains examples of how to use the module:
  - [Drupal single-node + custom network injected into module](examples/drupal-single-mds-use-existing-network): This is an example of how to use the oci-arch-drupal module to deploy Drupal (single-node) with MDS and network cloud infrastrucutre elements injected into the module.
  - [Drupal multi-node + custom network injected into module](examples/drupal-ha-mds-use-existing-network): This is an example of how to use the oci-arch-drupal module to deploy Drupal HA (multi-node) with MDS and network cloud infrastrucutre elements injected into the module.
  - [Drupal multi-node + custom network + Bastion Host injected into module](examples/drupal-ha-mds-use-existing-network-and-injected-bastion-host): This is an example of how to use the oci-arch-drupal module to deploy Drupal HA (multi-node) with MDS and network cloud infrastrucutre elements + Bastion Host injected into the module.
  - [Drupal multi-node + custom network + Bastion Service injected into module](examples/drupal-ha-mds-use-existing-network-and-injected-bastion-service): This is an example of how to use the oci-arch-wordpress module to deploy Drupal HA (multi-node) with MDS and network cloud infrastrucutre elements + Bastion Service injected into the module.  
To deploy Drupal using this Module with minimal effort use this:

```hcl
module "oci-arch-drupal" {
  source                    = "github.com/oracle-devrel/terraform-oci-arch-drupal"
  tenancy_ocid              = "<tenancy_ocid>"
  vcn_id                    = "<vcn_id>"
  numberOfNodes             = 1
  availability_domain_name  = "<availability_domain_name>"
  compartment_ocid          = "<compartment_ocid>""
  image_id                  = "<image_id>"
  shape                     = "<shape>"
  flex_shape_ocpus          = "<flex_shape_ocpus>"
  flex_shape_memory         = "<flex_shape_memory>" 
  label_prefix              = "<label_prefix>""
  ssh_authorized_keys       = "<ssh_public_key>"
  mds_ip                    = "<mysql_server_ip_address>"
  drupal_subnet_id          = "<drupal_subnet_id>"
  admin_password            = "<admin_password>"
  admin_username            = "<admin_username>"
  drupal_schema             = "<drupal_schema>"
  drupal_name               = "<drupal_name>"
  drupal_password           = "<drupal_password>"
  display_name              = "<drupal_instance_name>" 
}
```

Argument | Description
--- | ---
compartment_ocid | Compartment's OCID where Drupal will be created
use_existing_vcn | If you want to inject already exisitng VCN then you need to set the value to TRUE.
vcn_cidr | If use_existing_vcn is set to FALSE then you can define VCN CIDR block and then it will used to create VCN within the module.
vcn_id | If use_existing_vcn is set to TRUE then you can pass VCN OCID and module will use it to create Drupal installation.
numberOfNodes | If you need HA configuration with LB and FSS then set the value to 2 or more.
drupal_subnet_id | The OCID of the drupal public (single node) and private (multi node) subnet access. 
lb_subnet_id | If numberOfNodes set to 2 or more then you can provide OCID of the Load Balancer subnet.
bastion_subnet_id | If numberOfNodes set to 2 or more then you can use OCID of the Bastion subnet.
fss_subnet_id | If numberOfNodes set to 2 or more then you can use OCID of the File Storage Service subnet. 
availability_domain_name | The Availability Domain for deployment.
display_name | The name of the Drupal instance. 
shape | Instance shape to use for Drupal node.
flex_shape_ocpus | If shape is set to Flex shape then you can define Flex Shape OCPUs.
flex_shape_memory | If shape is set to Flex shape then you can define Flex Shape Memory (GB).
lb_shape | If numberOfNodes set to 2 or more then you can define Load Balancer shape
flex_lb_min_shape | If numberOfNodes set to 2 or more and lb_shape=flexible then you can define Load Balancer minimum shape.
flex_lb_max_shape | If numberOfNodes set to 2 or more and lb_shape=flexible then you can define Load Balancer maximum shape.
inject_bastion_service_id | Instead of counting on module to create Bastion Service you can pass Bastion Service OCID as input (set value to TRUE).
bastion_service_id | If inject_bastion_service_id is set to TRUE then you can pass here Bastion Service OCID as input.
inject_bastion_server_public_ip  | Instead of counting on module to create Bastion VM you can pass Bastion Host Public IP Address as input (set value to TRUE).
bastion_server_public_ip | If inject_bastion_server_public_ip is set to TRUE then you can pass here Bastion Host Public IP Address.
use_bastion_service | If you want to use OCI Bastion Service then you need to set the value to TRUE.
bastion_service_region | If use_bastion_service is set to TRUE then you can define bastion service region. 
bastion_image_id | If use_bastion_service is set to FALSE then you can define Bastion VM image id. 
bastion_shape | If use_bastion_service is set to FALSE then you can define Bastion VM shape.
bastion_flex_shape_ocpus | If use_bastion_service is set to FALSE and bastion_shape is using Flex shapes then you can define Flex Shape OCPUs.
bastion_flex_shape_memory | If use_bastion_service is set to FALSE and bastion_shape is using Flex shapes then you can define Flex Shape Memory (GB).
use_shared_storage | If numberOfNodes set to 2 or more then you can use shared NFS on OCI FSS (value TRUE). If you want to replicate Drupal by yourself (for example with rsync) then you can you can set the value to FALSE.
shared_working_dir | If numberOfNodes set to 2 or more then you can define shared mountpoint name.
label_prefix | To create unique identifier for multiple clusters in a compartment.
drupal_name | Drupal Database User Name for MySQL Server.
drupal_schema | Drupal Database User Schema for MySQL Server.
drupal_password | Drupal Database User Password for MySQL Server.
drupal_prefix | Drupal MySQL Prefix for tables (for example drupal_)
admin_username | Admin User Name for MySQL Server.
admin_password | Admin User Password for MySQL Server.
mds_ip | Private IP of the MySQL Server.
defined_tags | Defined tags to be added to compute instances.

## Contributing
This project is open source.  Please submit your contributions by forking this repository and submitting a pull request!  Oracle appreciates any contributions that are made by the open source community.

## License
Copyright (c) 2022 Oracle and/or its affiliates.

Licensed under the Universal Permissive License (UPL), Version 1.0.

See [LICENSE](LICENSE) for more details.
