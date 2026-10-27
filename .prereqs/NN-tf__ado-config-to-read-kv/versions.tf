terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "=3.10.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "=1.16.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=5.6.0"
    }
  }
}
