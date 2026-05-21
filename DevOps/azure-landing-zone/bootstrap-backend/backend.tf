terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "satishlzstate001"
    container_name       = "tfstate"
    key                  = "landingzone.tfstate"
  }
}