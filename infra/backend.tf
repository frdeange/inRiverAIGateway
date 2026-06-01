# Backend local por defecto. Cuando elijas storage, descomenta el bloque
# `azurerm` y elimina el `local` (o ejecuta `terraform init -migrate-state`).

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }

  # backend "azurerm" {
  #   resource_group_name  = "iagw-tfstate-rg"
  #   storage_account_name = "iagwtfstatesa"
  #   container_name       = "tfstate"
  #   key                  = "inriver-aigw.tfstate"
  #   use_azuread_auth     = true
  # }
}
