variable "landing_zones" {

  type = map(object({
    location      = string
    address_space = list(string)

    subnets = map(list(string))

    tags = map(string)
  }))
}

variable "devops_group_id" {
  type = string
}

variable "tenant_id" {
  type = string
}