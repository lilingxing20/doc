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
  user_name   = var.openstack-user
  tenant_name = var.openstack-tenant-name
  password    = var.openstack-password
  auth_url    = var.openstack-auth-url
  region      = var.openstack-region
}

### 创建 Flavor
resource "openstack_compute_flavor_v2" "flavor" {
  name  = var.openstack-flavor-name
  ram   = var.openstack-flavor-ram
  vcpus = var.openstack-flavor-vcpus
  disk  = var.openstack-flavor-disk
  is_public = "true"
}

### 创建keypair
resource "openstack_compute_keypair_v2" "keypair" {
  name = var.openstack-keypair-name
  public_key = file("~/.ssh/id_rsa.pub")
}

##查找已上传的镜像
data "openstack_images_image_v2" "image" {
    name = var.openstack-image-name
}

### 查找已创建网络
data "openstack_networking_network_v2" "network" {
   name = var.openstack-network-name
}

data "openstack_networking_subnet_v2" "subnet" {
   name = var.openstack-subnet-name
}


### 安全组
## 查找
# data "openstack_networking_secgroup_v2" "secgroup" {
#     name = var.openstack-security-group-name1
# }
## 创建
resource "openstack_compute_secgroup_v2" "secgroup" {
    name        = var.openstack-security-group-name2
    description = "my security group"
 
    rule {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr        = "0.0.0.0/0"
    }
    rule {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr        = "0.0.0.0/0"
    }
    rule {
      from_port   = -1
      to_port     = -1
      ip_protocol = "icmp"
      cidr        = "0.0.0.0/0"
    }
}

### 创建port
resource "openstack_networking_port_v2" "port" {
    count          = var.vm-count
    name           = "${var.openstack-network-port}-${count.index + 1}"
    admin_state_up = "true"

    network_id = data.openstack_networking_network_v2.network.id

    fixed_ip {
        subnet_id = data.openstack_networking_subnet_v2.subnet.id
        ip_address = var.all_ips[count.index]
    }
    
    #security_group_ids = [
    #    data.openstack_networking_secgroup_v2.secgroup.id
    #]
    security_group_ids = [
        openstack_compute_secgroup_v2.secgroup.id
    ]
}

### 创建卷
# resource "openstack_blockstorage_volume_v1" "myvol" {
#     name     = "myvol"
#     size     = 5
#     image_id = data.openstack_images_image_v2.image.id
# }
# resource "openstack_blockstorage_volume_v2" "volume_1" {
#     name = "volume_1"
#     size = 1
# }

### 创建虚拟机
resource "openstack_compute_instance_v2" "instance" {
    count = var.vm-count
    name  = "${var.vm-name-prefix}-${count.index + 1}"
    image_id = data.openstack_images_image_v2.image.id
    flavor_id = openstack_compute_flavor_v2.flavor.id
    key_pair = openstack_compute_keypair_v2.keypair.name
    security_groups = var.openstack-security-groups

    ## Instance with User Data (cloud-init).
    user_data = file("user-data.txt")

    ## Instance with Swap Disk
    # block_device {
    #     boot_index            = -1
    #     delete_on_termination = true
    #     destination_type      = "local"
    #     source_type           = "blank"
    #     guest_format          = "swap"
    #     volume_size           = 4
    # }

    ## Instance with Multiple Ephemeral Disks
    # block_device {
    #     boot_index            = -1
    #     delete_on_termination = true
    #     destination_type      = "local"
    #     source_type           = "blank"
    #     volume_size           = 1
    #     guest_format          = "ext4"
    # }

    ## 镜像创建虚拟机
    block_device {
       uuid                  = data.openstack_images_image_v2.image.id
       source_type           = "image"
       destination_type      = "local"
       boot_index            = 0
       volume_size           = null
       delete_on_termination = true
     }

    ## Boot From Volume.
    # block_device {
    #    uuid                  = data.openstack_images_image_v2.image.id
    #    source_type           = "image"
    #    destination_type      = "volume"
    #    volume_size           = 10
    #    boot_index            = 0
    #    delete_on_termination = true

    ## Boot From an Existing Volume.
    # block_device {
    #     uuid                  = "${openstack_blockstorage_volume_v1.myvol.id}"
    #     source_type           = "volume"
    #     destination_type      = "volume"
    #     boot_index            = 0
    #     delete_on_termination = true
    # }

    ## Boot Instance, Create Volume, and Attach Volume as a Block Device.
    block_device {
      source_type           = "blank"
      destination_type      = "volume"
      volume_size           = var.vm-disk-size
      boot_index            = 1
      delete_on_termination = true
    }

    ## Boot Instance and Attach Existing Volume as a Block Device.
    # block_device {
    #     uuid                  = "${openstack_blockstorage_volume_v2.volume_1.id}"
    #     source_type           = "volume"
    #     destination_type      = "volume"
    #     boot_index            = 2
    #     delete_on_termination = true
    # }
    
    network {
        port = openstack_networking_port_v2.port[count.index].id
    }

    connection {
      user        = "centos"
      host        = openstack_networking_port_v2.port[count.index].fixed_ip.0.ip_address
      #host        = var.all_ips[count.index]
      private_key = file("~/.ssh/id_rsa")
    }
    
    provisioner "remote-exec" {
      inline = [
        "echo terraform executed > /tmp/foo",
      ]
    }

    tags = [
        "tag01"
    ]
}
