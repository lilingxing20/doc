### 定义 OpenStack Provider
terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}

### 配置 OpenStack Provider
provider "openstack" {
  user_name   = "admin"
  tenant_name = "admin"
  password    = "123456"
  auth_url    = "http://172.30.126.213:5000/v3"
  region      = "RegionOne"
}

### 创建 Flavor
resource "openstack_compute_flavor_v2" "flavor" {
  name  = "flavor01"
  ram   = "1024"
  vcpus = "1"
  disk  = "10"
  is_public = "true"

  # extra_specs = {
  #   "hw:cpu_policy"        = "CPU-POLICY",
  #   "hw:cpu_thread_policy" = "CPU-THREAD-POLICY"
  # }
}

### 创建keypair
resource "openstack_compute_keypair_v2" "keypair" {
  name = "keypair01"
}


### 上传镜像
resource "openstack_images_image_v2" "image" {
  name             = "centos7-qcow2"
  image_source_url = "http://172.16.134.33/qcow2/CentOS-7-x86_64-GenericCloud-1708-passw0rd.qcow2"
  container_format = "bare"
  disk_format      = "qcow2"

  # properties = {
  #   key = "value"
  # }
}


### 创建网络
resource "openstack_networking_network_v2" "network" {
  name           = "net50"
  admin_state_up = "true"
}

### 创建子网
resource "openstack_networking_subnet_v2" "subnet" {
  name       = "subnet50"
  network_id = "${openstack_networking_network_v2.network.id}"
  cidr       = "50.50.50.0/24"
  ip_version = 4
}

### 创建安全组
resource "openstack_compute_secgroup_v2" "secgroup" {
  name        = "sg01"
  description = "a security group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

### 创建Port
resource "openstack_networking_port_v2" "port" {
  name               = "port_1"
  network_id         = "${openstack_networking_network_v2.network.id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup.id}"]

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.subnet.id
    ip_address = "50.50.50.10"
  }
}


### 创建虚拟机
resource "openstack_compute_instance_v2" "instance" {
  name            = "instance_1"
  image_id        = openstack_images_image_v2.image.id
  flavor_id       = openstack_compute_flavor_v2.flavor.id
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = ["${openstack_compute_secgroup_v2.secgroup.name}"]

  network {
    name = openstack_networking_network_v2.network.name
  }
}


### 创建数据卷 Volume
resource "openstack_blockstorage_volume_v2" "volume_v2" {
  name        = "volume_2"
  description = "secend test volume"
  volume_type = "rbd"
  size        = 2
}
resource "openstack_blockstorage_volume_v3" "volume_v3" {
  name        = "volume_3"
  description = "third test volume"
  volume_type = "rbd"
  size        = 3
}
resource "openstack_blockstorage_volume_v2" "volumes" {
  count       = 2
  name        = "${format("vol-%02d", count.index + 1)}"
  description = "${format("test volume %02d", count.index + 1)}"
  volume_type = "rbd"
  size  = 1
}

### 虚拟机附加数据卷
resource "openstack_compute_volume_attach_v2" "attachments" {
  count       = 2
  instance_id = openstack_compute_instance_v2.instance.id
  volume_id   = openstack_blockstorage_volume_v2.volumes.*.id[count.index]
}


### 输出信息
output "flavor-id" {
  value = openstack_compute_flavor_v2.flavor.id
}
output "image-id" {
  value = openstack_images_image_v2.image.id
}
output "keypair-id" {
  value = openstack_compute_keypair_v2.keypair.id
}
output "network-id" {
  value = openstack_networking_network_v2.network.id
}
output "subnet-id" {
  value = openstack_networking_subnet_v2.subnet.id
}
output "secgroup-id" {
  value = openstack_compute_secgroup_v2.secgroup.id
}
output "port-id" {
  value = openstack_networking_port_v2.port.id
}
output "instance-id" {
  value = openstack_compute_instance_v2.instance.id
}
output "volume-v2-id" {
  value = openstack_blockstorage_volume_v2.volume_v2.id
}
output "volume-v3-id" {
  value = openstack_blockstorage_volume_v3.volume_v3.id
}
output "volume_devices" {
  value = openstack_compute_volume_attach_v2.attachments.*.device
}
