variable "vm_name" {
  type        = string
  description = "VM Name"
}

variable "rules" {
  type = map(object({
    rule_name = rule_name
    port      = port
    priority  = string
  }))
  description = "nsg rules"
}
