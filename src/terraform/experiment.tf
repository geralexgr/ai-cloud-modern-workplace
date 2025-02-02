terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }
}

provider "azurerm" {
   features {}
   subscription_id = var.subscription_id
   skip_provider_registration = "true"
}

resource "azurerm_resource_group" "chaos_rg" {
  name     = var.resource_group
  location = var.region
}


data "azurerm_windows_web_app" "chaos_web_app" {
  name                = "chaos"
  resource_group_name = var.webapp_resource_group
}


resource "azurerm_chaos_studio_target" "chaos_target" {
  location           = var.region
  target_resource_id = data.azurerm_windows_web_app.chaos_web_app.id
  target_type        = "Microsoft-AppService"
}


resource "azurerm_chaos_studio_capability" "example" {
  chaos_studio_target_id = azurerm_chaos_studio_target.chaos_target.id
  capability_type        = "Stop-1.0"
}

resource "azurerm_chaos_studio_experiment" "app_service_shutdown" {
  name                = "app-service-shutdown-experiment"
  location            = azurerm_resource_group.chaos_rg.location
  resource_group_name = azurerm_resource_group.chaos_rg.name

  identity {
    type = "SystemAssigned"
  }
  
  selectors {
    name                    = "Selector1"
    chaos_studio_target_ids = [azurerm_chaos_studio_target.chaos_target.id]
  }

  steps {
    name = "example"
    branch {
      name = "example"
      actions {
        urn           = azurerm_chaos_studio_capability.example.urn
        selector_name = "Selector1"
        parameters = {
          abruptShutdown = "false"
        }
        action_type = "continuous"
        duration    = "PT10M"
      }
    }
  }
}