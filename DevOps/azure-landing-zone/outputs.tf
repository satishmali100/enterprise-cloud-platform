output "resource_groups" {
  value = {
    for k, rg in module.resource_groups : k => rg.name
  }
}

output "vnets" {
  value = {
    for k, vnet in module.networking : k => vnet.vnet_name
  }
}

output "nsgs" {
  value = {
    for k, nsg in module.nsg : k => nsg.nsg_id
  }
}

output "log_analytics" {
  value = {
    for k, law in module.monitoring : k => law.workspace_id
  }
}

output "subnets" {
  value = {
    for k, subnet in module.subnets : k => subnet.subnet_id
  }
}

output "security_keyvaults" {
  value = {
    for k, kv in module.security : k => kv.key_vault_id
  }
}