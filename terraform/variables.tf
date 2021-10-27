variable "libvirt_url" {
  type = string
  default = "qemu:///system"
}

variable "node_ipv4_subnet" {
  type = string
  default = "192.168.200.0/24"
  validation { 
    condition = can(regex("(^192\\.168)(\\.)([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\\.)([0-9]{1,2}|2[0-4][0-9]|25[0-5])(\\/24)",var.node_ipv4_subnet))
    error_message = "Variable node_ipv4_subnet must be a /24 in the 192.168.0.0/16 range."
  }
}

variable "worker_nodes" {
  type = number
  default = 2
  validation {
    condition = var.worker_nodes >= 2 && var.worker_nodes <= 7
    error_message = "Variable worker_nodes must be 2 <= and >= 7."
  }
}
