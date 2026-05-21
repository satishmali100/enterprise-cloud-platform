resource "azurerm_policy_definition" "allowed_locations" {
  name         = "lz-allowed-locations"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Landing Zone - Allowed Locations"

  policy_rule = jsonencode({
    if = {
      field = "location"
      notIn = var.allowed_locations
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "allowed_locations" {
  name                 = "lz-allowed-locations-assignment"
  resource_group_id    = var.scope_id
  policy_definition_id = azurerm_policy_definition.allowed_locations.id
}