### 初始化provider vsphere
terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
      version = "1.24.3"
    }
  }
}

### 连接 vsphere
provider "vsphere" {
  user           = "administrator@vsphere.local"
  password       = "Teamsun@1"
  vsphere_server = "172.30.126.50"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

### 定义变量
variable "datacenter" {
  default = "terraform-dc01"
}
variable "cluster" {
  default = "terraform-cluster01"
}
variable "hosts" {
  default = [
    {"host": "172.30.126.62", "user": "root", "pass": "P@ssw0rd"}
  ]
}
variable "host_license" {
  default = "JJ2WR-25L9P-H71A8-6J20P-C0K3F"
}
variable "dvs" {
  default = "terraform-dvs01"
}
variable "dvs_pg" {
  default = "terraform-dvs_pg01"
}
variable "dvs_pg_vlanid" {
  default = 1234
}
variable "dvs_uplink_nic" {
  default = [
    "vmnic1"
  ]
}

### 创建数据中心 Datacenter
resource "vsphere_datacenter" "dc1" {
  name = "${var.datacenter}"
}

### 创建集群 Cluster
resource "vsphere_compute_cluster" "cluster" {
  name            = "${var.cluster}"
  datacenter_id   = vsphere_datacenter.dc1.moid
  depends_on      = [vsphere_datacenter.dc1]
}
 
### 在集群中添加主机 Host
resource "vsphere_host" "hs1" {
  count      = "${length(var.hosts)}"
  hostname   = "${var.hosts[count.index].host}"
  username   = "${var.hosts[count.index].user}"
  password   = "${var.hosts[count.index].pass}"
  license    = "${var.host_license}"
  cluster    = vsphere_compute_cluster.cluster.id
  depends_on = [vsphere_compute_cluster.cluster]
}

### 创建分布式交换机 dvs
resource "vsphere_distributed_virtual_switch" "dvs1" {
  name             = "${var.dvs}"
  datacenter_id    = vsphere_datacenter.dc1.moid
  host {
    host_system_id = vsphere_host.hs1.0.id
    devices        = "${var.dvs_uplink_nic}"
  }
  # host {
  #   host_system_id = vsphere_host.hs1.1.id
  #   devices        = "${var.dvs_uplink_nic}"
  # }
  depends_on       = [vsphere_host.hs1]
}

### 创建分布式端口组 PortGroup
resource "vsphere_distributed_port_group" "dvs_pg1" {
  name                            = "${var.dvs_pg}"
  vlan_id                         = "${var.dvs_pg_vlanid}"
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.dvs1.id
  depends_on                      = [vsphere_distributed_virtual_switch.dvs1]
}

### 创建 VMkernel 适配器
# resource "vsphere_vnic" "vnic1" {
#   count                   = "${length(vsphere_datacenter.hs1)}"
#   host                    = vsphere_host.hs1[count.index].id
#   distributed_switch_port = vsphere_distributed_virtual_switch.dvs1.id
#   distributed_port_group  = vsphere_distributed_port_group.dvs_pg1.id
#   ipv4 {
#     dhcp = true
#   }
#   netstack                = "vmotion"
#   depends_on              = [vsphere_distributed_port_group.dvs_pg1]
# }


### 过滤数据存储使用的存储设备
data "vsphere_vmfs_disks" "available" {
  host_system_id = vsphere_host.hs1.0.id
  rescan         = true
  filter         = "mpx.vmhba0:C0:T0:L0"
}

### 创建 VMFS 类型的数据存储 Datastore
resource "vsphere_vmfs_datastore" "datastore" {
  name           = "terraform-test"
  host_system_id = vsphere_host.hs1.0.id
  depends_on     = [vsphere_host.hs1]

  disks = "${data.vsphere_vmfs_disks.available.disks}"
}


### 创建虚拟机
# resource "vsphere_virtual_machine" "vm" {
#   name             = "terraform-test"
#   resource_pool_id = vsphere_compute_cluster.cluster.resource_pool_id
#   datastore_id     = vsphere_vmfs_datastore.datastore.id
# 
#   num_cpus = 1
#   memory   = 1024
#   guest_id = "other3xLinux64Guest"
# 
#   network_interface {
#     network_id = vsphere_distributed_port_group.dvs_pg1.id
#   }
# 
#   disk {
#     label = "disk0"
#     size  = 10
#   }
# }


### 使用本地 OVF 模版部署虚拟机
# resource "vsphere_virtual_machine" "vmFromLocalOvf" {
#   name                       = "terraform-vm1"
#   datacenter_id              = vsphere_datacenter.dc1.moid
#   resource_pool_id           = vsphere_compute_cluster.cluster.resource_pool_id
#   datastore_id               = vsphere_vmfs_datastore.datastore.id
#   host_system_id             = vsphere_host.hs1.0.id
#   wait_for_guest_net_timeout = 0
#   wait_for_guest_ip_timeout  = 0
#   ovf_deploy {
#     // Full Path to local ovf/ova file
#     local_ovf_path       = "/var/www/html/vmware/ova/test1.ova"
#     disk_provisioning    = "thin"
#     ip_protocol          = "IPV4"
#     ip_allocation_policy = "STATIC_MANUAL"
#   }
#   network_interface {
#     network_id = vsphere_distributed_port_group.dvs_pg1.id
#   }
# }

### 使用远程 OVF 模版部署虚拟机
# resource "vsphere_virtual_machine" "vmFromLocalOvf" {
resource "vsphere_virtual_machine" "vmFromRemoteOvf" {
  name                       = "terraform-vm2"
  datacenter_id              = vsphere_datacenter.dc1.moid
  resource_pool_id           = vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id               = vsphere_vmfs_datastore.datastore.id
  host_system_id             = vsphere_host.hs1.0.id
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0
  ovf_deploy {
    // Full Path to local ovf/ova file
    remote_ovf_url       = "http://172.16.134.33/vmware/ova/CentOS-72-1511-template.ova"
  }
  network_interface {
    network_id = vsphere_distributed_port_group.dvs_pg1.id
  }

  depends_on = [
    vsphere_host.hs1,
    vsphere_vmfs_datastore.datastore,
    vsphere_distributed_port_group.dvs_pg1
  ]
}
