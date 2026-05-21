resource "azurerm_resource_group" "tfstate" {
  name     = "tfstate-rg"
  location = "eastus"
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "satishlzstate001"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  lifecycle {
    prevent_destroy = false
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "satishm.tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}