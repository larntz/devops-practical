variable "libvirt_url" {
  type = string
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

