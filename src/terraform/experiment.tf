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
   subscription_id = "43709a15-a023-45e7-90a6-e30c5ffad83e"
   skip_provider_registration = "true"
}

resource "azurerm_resource_group" "example" {
  name     = "chaos_terraform"
  location = "West Europe"
}


data "azurerm_windows_web_app" "example" {
  name                = "chaos"
  resource_group_name = "CHAOS"
}


resource "azurerm_chaos_studio_target" "example" {
  location           = "West Europe"
  target_resource_id = data.azurerm_windows_web_app.example.id
  target_type        = "Microsoft-AppService"
}


resource "azurerm_chaos_studio_capability" "example" {
  chaos_studio_target_id = azurerm_chaos_studio_target.example.id
  capability_type        = "Stop-1.0"
}

resource "azurerm_chaos_studio_experiment" "app_service_shutdown" {
  name                = "app-service-shutdown-experiment"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  identity {
    type = "SystemAssigned"
  }
  
  selectors {
    name                    = "Selector1"
    chaos_studio_target_ids = [azurerm_chaos_studio_target.example.id]
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