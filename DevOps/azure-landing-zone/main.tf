
# module "dev_rg" {
#   source = "./modules/resource_group"

#   name     = "module-dev-rg"
#   location = "eastus"

#   tags = {
#     environment = "dev"
#     owner       = "satish"
#   }
# }

# module "uat_rg" {
#   source = "./modules/resource_group"

#   name     = "module-uat-rg"
#   location = "westus"

#   tags = {
#     environment = "uat"
#     owner       = "satish"
#   }
# }

# module "prod_rg" {
#   source = "./modules/resource_group"

#   name     = "module-prod-rg"
#   location = "westus"

#   tags = {
#     environment = "prod"
#     owner       = "satish"
#   }
# }

module "resource_groups" {
  source = "./modules/resource_group"

  for_each = var.landing_zones

  name     = "module-${each.key}-rg"
  location = each.value.location
  tags     = each.value.tags
}

module "networking" {
  source = "./modules/networking"

  for_each = var.landing_zones

  vnet_name           = "${each.key}-vnet"
  location            = each.value.location
  resource_group_name = module.resource_groups[each.key].name
  address_space       = each.value.address_space
  tags                = each.value.tags
}

module "nsg" {
  source = "./modules/nsg"

  for_each = var.landing_zones

  nsg_name            = "${each.key}-nsg"
  location            = each.value.location
  resource_group_name = module.resource_groups[each.key].name
  tags                = each.value.tags
}

module "monitoring" {
  source = "./modules/monitoring"

  for_each = var.landing_zones

  workspace_name      = "${each.key}-law"
  location            = each.value.location
  resource_group_name = module.resource_groups[each.key].name
  tags                = each.value.tags
}

module "subnets" {

  source = "./modules/subnet"

  for_each = {
    for item in flatten([
      for env_name, env in var.landing_zones : [
        for subnet_name, prefixes in env.subnets : {
          key         = "${env_name}-${subnet_name}"
          env_name    = env_name
          subnet_name = subnet_name
          prefixes    = prefixes
        }
      ]
    ]) : item.key => item
  }

  subnet_name          = each.value.subnet_name
  resource_group_name  = module.resource_groups[each.value.env_name].name
  virtual_network_name = module.networking[each.value.env_name].vnet_name
  address_prefixes     = each.value.prefixes
}

module "nsg_association" {
  source = "./modules/nsg_association"

  for_each = module.subnets

  subnet_id = each.value.subnet_id
  nsg_id    = module.nsg[split("-", each.key)[0]].nsg_id
}

module "governance_policy" {
  source = "./modules/governance_policy"

  for_each = module.resource_groups

  scope_id          = each.value.id
  allowed_locations = ["eastus", "westus", "westeurope"]
}

module "rbac" {
  source = "./modules/rbac"

  for_each = module.resource_groups

  scope_id     = each.value.id
  principal_id = var.devops_group_id
  role_name    = each.key == "prod" ? "Reader" : "Contributor"
}

module "security" {
  source = "./modules/security"

  for_each = var.landing_zones

  key_vault_name      = "kv-${each.key}-lz-001"
  location            = each.value.location
  resource_group_name = module.resource_groups[each.key].name
  tenant_id           = var.tenant_id
  tags                = each.value.tags
}

module "keyvault_compliance" {
  source = "./modules/compliance"

  for_each = module.security

  name                       = "diag-${each.key}-keyvault"
  target_resource_id         = each.value.key_vault_id
  log_analytics_workspace_id = module.monitoring[each.key].workspace_id
}