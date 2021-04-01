terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "mypool01" {
  name = "mypool01"
  type = "dir"
  path = "/tmp/kvm"
}

resource "libvirt_volume" "volume-image-centos7" {
  name   = "volume-image-centos7.qcow2"
  pool   = libvirt_pool.mypool01.name
  source = "http://172.16.194.143/images/GenericCloud/CentOS-7-x86_64-GenericCloud-1811-passw0rd.qcow2"
  format =  "qcow2"
}
resource "libvirt_volume" "volume-boot" {
  count          = 1
  name           = "volume-boot-${count.index}"
  base_volume_id = libvirt_volume.volume-image-centos7.id
  pool           = libvirt_pool.mypool01.name
  format         = "qcow2"
  size           = 1024 * 1024 * 1024 * 10
}


data "template_file" "cloudinit_network" {
  template = file("network_config.cfg")
}
data "template_file" "cloudinit_data" {
  template = file("cloud_init.cfg")
  vars = {
    pwd = 123456
  }
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name           = "cloudinit.iso"
  user_data      = data.template_file.cloudinit_data.rendered
  network_config = data.template_file.cloudinit_network.rendered
  pool           = libvirt_pool.mypool01.name
}
resource "libvirt_network" "network01" {
  name      = "network01"
  mode      = "nat"
  addresses = ["192.168.0.0/24"]
  domain    = "net50.local"
  #dhcp {
  #   enabled = true
  #}
  # Enables usage of the host dns if no local records match
  dns {
    enabled = true
    local_only = true
  }
}

resource "libvirt_domain" "terraform_test" {
  count  = 1
  name   = "terraform-vm02"
  memory = 2048
  vcpu   = 4
  cloudinit = libvirt_cloudinit_disk.cloudinit.id

  network_interface {
    network_id = libvirt_network.network01.id
    addresses = ["192.168.0.10"]
    # Required to get ip address in the output when using dhcp
    wait_for_lease = true
    hostname  = "vm02.local"
  }
  #network_interface {
  #  network_name = "zrzvagrant0"
  #  mac          = "00:11:22:33:44:55"
  #  hostname     = "vm02.local"
  #  addresses    = ["192.168.40.10"]
  #  # Required to get ip address in the output when using dhcp
  #  wait_for_lease = true
  #}

  disk {
    volume_id = element(libvirt_volume.volume-boot.*.id, count.index)
  }

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }
  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  #graphics {
  #  type        = "spice"
  #  listen_type = "address"
  #  autoport     = true
  #}
  graphics {
    type           = "vnc"
    listen_type    = "address"
    listen_address = "0.0.0.0"
  }
   
  provisioner "local-exec" {
    command = "while true; do ping -c 1 $IP; [ $? == 0 ] && break; sleep 1; done"
    environment = {
      IP = libvirt_domain.terraform_test[count.index].network_interface.0.addresses[0]
    }
  }
  connection {
    user        = "root"
    host        = libvirt_domain.terraform_test[count.index].network_interface.0.addresses[0]
    private_key = file("~/.ssh/id_rsa")
  }
  provisioner "remote-exec" {
    inline = [
      "echo terraform executed > /tmp/foo",
      "ip a > /tmp/ip",
      "cp /etc/sysconfig/network-scripts/ifcfg-eth0 /tmp/",
    ]
  }
}

output "ips" {
  value = libvirt_domain.terraform_test.*.network_interface.0.addresses
}


