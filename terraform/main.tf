terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_url
}

resource "random_string" "deployment_id" {
  length = 6
  special = false
  lower = true
  upper = false
  number = false
}

resource "libvirt_network" "k8snet" {
  name = "${ random_string.deployment_id.result }-k8s-net"
  mode = "route"
  domain = "k8s.local"
  addresses = [var.node_ipv4_subnet]
  dns { 
    enabled = true
    local_only = false
  }
}

resource "libvirt_volume" "os_image" {
  name = "debian-bullseye.qcow2"
  #source = "https://cloud.debian.org/images/cloud/bullseye/20211011-792/debian-11-generic-amd64-20211011-792.qcow2"
  source = "../packer-builds/packer-debian-11.1-amd64-qemu/debian-11.1-amd64"
}

resource "libvirt_volume" "lb-volume" {
  name  = "${ random_string.deployment_id.result }-lb-vol-00.qcow2"
  base_volume_id = libvirt_volume.os_image.id
}

resource "libvirt_volume" "cp-volume" {
  count = 3
  name  = "${ random_string.deployment_id.result }-cp-vol-0${count.index}.qcow2"
  base_volume_id = libvirt_volume.os_image.id
}

resource "libvirt_volume" "wk-volume" {
  count = var.worker_nodes
  name  = "${ random_string.deployment_id.result }-wk-vol-0${count.index}.qcow2"
  base_volume_id = libvirt_volume.os_image.id
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "${ random_string.deployment_id.result }-commoninit.iso"
  user_data = data.template_file.user_data.rendered
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

resource "libvirt_domain" "lb-domain" {
  vcpu = 2
  memory = "4096"
  name = "${ random_string.deployment_id.result }-lb-00"
  qemu_agent = true
  cloudinit = libvirt_cloudinit_disk.commoninit.id
  graphics {
    type        = "vnc"
    listen_type = "address"
    listen_address = "0.0.0.0"
  }
  disk {
    volume_id = libvirt_volume.lb-volume.id
  }
  network_interface {
    network_name = libvirt_network.k8snet.name
    wait_for_lease = true
  }
}

resource "libvirt_domain" "cp-domain" {
  count = 3
  vcpu = 4
  memory = "8192"
  name = "${ random_string.deployment_id.result }-cp-0${count.index}"
  qemu_agent = true
  cloudinit = libvirt_cloudinit_disk.commoninit.id
  graphics {
    type        = "vnc"
    listen_type = "address"
    listen_address = "0.0.0.0"
  }
  disk {
    volume_id = element(libvirt_volume.cp-volume.*.id, count.index)
  }
  network_interface {
    network_name = libvirt_network.k8snet.name
    wait_for_lease = true
  }
}

resource "libvirt_domain" "wk-domain" {
  count = var.worker_nodes
  vcpu = 4 
  memory = "16384"
  name = "${ random_string.deployment_id.result }-wk-0${count.index}"
  qemu_agent = true
  cloudinit = libvirt_cloudinit_disk.commoninit.id
  graphics {
    type        = "vnc"
    listen_type = "address"
    listen_address = "0.0.0.0"
  }
  disk {
    volume_id = element(libvirt_volume.wk-volume.*.id, count.index)
  }
  network_interface {
    network_name = libvirt_network.k8snet.name
    wait_for_lease = true
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("hosts.template", 
    {
      ansible_group_control = libvirt_domain.cp-domain.*.name,
      ansible_control_ips   = libvirt_domain.cp-domain.*.network_interface.0.addresses.0,
      ansible_group_workload = libvirt_domain.wk-domain.*.name,
      ansible_workload_ips = libvirt_domain.wk-domain.*.network_interface.0.addresses.0,
      ansible_lb_name = libvirt_domain.lb-domain.name,
      ansible_lb_ip = libvirt_domain.lb-domain.network_interface.0.addresses.0,
    }
  )
  filename = "../cluster-hosts"
  file_permission = "0644"
}

#resource "local_file" "known_hosts" {
#  filename = "known_hosts"
#  file_permission = "0644"
#}

