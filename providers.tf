terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.35.0"
    }
  }

  backend "azurerm" {
    # intentionally blank
  }
}

provider "azurerm" {
  # Configuration options
  subscription_id = var.subscription_id
  features {}
}