variable "libvirt_url" {
  type = string
  #qemu+ssh://larntz@dell-r710/system?no_verify=1
  default = "qemu:///system"
}

variable "control_nodes" {
  type = number
  default = 3
}

variable "worker_nodes" {
  type = number
  default = 2
}

