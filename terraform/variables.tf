variable "libvirt_url" {
  type = string
  default = "qemu:///system"
}

variable "worker_nodes" {
  type = number
  default = 2
  validation {
    condition = var.worker_nodes >= 2 && var.worker_nodes <= 7
    error_message = "Variable worker_nodes must be 2 <= and >= 7."
  }
}
