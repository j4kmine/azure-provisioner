variable "name" {
  description = "The name of the storage account"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "account_tier" {
  description = "The storage account tier"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "The storage account replication type"
  type        = string
  default     = "LRS"
}

variable "is_hns_enabled" {
  description = "Is Hierarchical Namespace enabled"
  type        = bool
  default     = false
}

variable "containers" {
  description = "Blob containers to create"
  type        = list(map(string))
  default     = []
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}

resource "azurerm_storage_account" "storage" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  is_hns_enabled           = var.is_hns_enabled
  tags                     = var.tags
  
  blob_properties {
    versioning_enabled = true
    
    container_delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "container" {
  count                 = length(var.containers)
  name                  = var.containers[count.index].name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = lookup(var.containers[count.index], "container_access_type", "private")
}

output "storage_account_id" {
  description = "The ID of the Storage Account"
  value       = azurerm_storage_account.storage.id
}

output "storage_account_name" {
  description = "The name of the Storage Account"
  value       = azurerm_storage_account.storage.name
}

output "storage_account_primary_connection_string" {
  description = "The primary connection string of the Storage Account"
  value       = azurerm_storage_account.storage.primary_connection_string
  sensitive   = true
}

output "storage_account_primary_access_key" {
  description = "The primary access key of the Storage Account"
  value       = azurerm_storage_account.storage.primary_access_key
  sensitive   = true
}
