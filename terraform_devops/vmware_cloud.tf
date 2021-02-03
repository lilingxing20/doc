### init provider vsphere
terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
      version = "1.24.3"
    }
  }
}

### connect vsphere
provider "vsphere" {
  user           = "administrator@vsphere.local"
  password       = "Teamsun@1"
  vsphere_server = "172.30.126.50"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

### Define variables
variable "datacenter" {
  default = "DC01"
}
variable "cluster" {
  default = "Cluster01"
}
variable "host" {
  default = "172.30.126.62"
}
variable "dvs" {
  default = "dvs01"
}
variable "dvs_pg" {
  default = "dvs_pg01"
}
variable "dvs_uplink_nic" {
  default = [
    "vmnic1"
  ]
}

### Create DC
resource "vsphere_datacenter" "dc1" {
  name = "${var.datacenter}"
}

### Create Cluster
resource "vsphere_compute_cluster" "cluster" {
  name          = "${var.cluster}"
  datacenter_id = vsphere_datacenter.dc1.id
}

### Add Host
resource "vsphere_host" "hs1" {
  hostname = "${var.host}"
  username = "root"
  password = "password"
  license  = "JJ2WR-25L9P-H71A8-6J20P-C0K3F"
  cluster  = vsphere_compute_cluster.cluster.id
}

### Create DVS and PG
resource "vsphere_distributed_virtual_switch" "dvs1" {
  name          = "${var.dvs}"
  datacenter_id = vsphere_datacenter.dc1.id
  host {
    host_system_id = vsphere_host.hs1.id
    devices        = "${var.dvs_uplink_nic}"
  }
}

resource "vsphere_distributed_port_group" "dvs_pg1" {
  name                            = "${var.dvs_pg}"
  vlan_id                         = 1234
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.dvs1.id
}

resource "vsphere_vnic" "vnic1" {
  host                    = vsphere_host.hs1.id
  distributed_switch_port = vsphere_distributed_virtual_switch.dvs1.id
  distributed_port_group  = vsphere_distributed_port_group.dvs_pg1.id
  ipv4 {
    dhcp = true
  }
  netstack = "vmotion"
}


### Create VMFS Datastore
data "vsphere_vmfs_disks" "available" {
  host_system_id = vsphere_host.hs1.id
  rescan         = true
  filter         = "mpx.vmhba0:C0:T0:L0"
}

resource "vsphere_vmfs_datastore" "datastore" {
  name           = "terraform-test"
  host_system_id = vsphere_host.hs1.id
  folder         = "datastore-folder"

  disks = "${data.vsphere_vmfs_disks.available.disks}"
}


### Create VM
resource "vsphere_virtual_machine" "vm" {
  name             = "terraform-test"
  resource_pool_id = vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = vsphere_vmfs_datastore.datastore.id

  num_cpus = 1
  memory   = 1024
  guest_id = "other3xLinux64Guest"

  network_interface {
    network_id = vsphere_distributed_port_group.dvs_pg1.id
  }

  disk {
    label = "disk0"
    size  = 10
  }
}
