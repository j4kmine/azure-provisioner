variable "name" {
  description = "The name of the Databricks workspace"
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

variable "sku" {
  description = "The SKU of the Databricks workspace (standard, premium, trial)"
  type        = string
  default     = "standard"
}

variable "managed_resource_group_name" {
  description = "The name of the managed resource group"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}

resource "azurerm_databricks_workspace" "databricks" {
  name                        = var.name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  sku                         = var.sku
  managed_resource_group_name = var.managed_resource_group_name
  tags                        = var.tags
}

output "databricks_workspace_id" {
  description = "The ID of the Databricks workspace"
  value       = azurerm_databricks_workspace.databricks.id
}

output "databricks_workspace_name" {
  description = "The name of the Databricks workspace"
  value       = azurerm_databricks_workspace.databricks.name
}

output "databricks_workspace_url" {
  description = "The URL of the Databricks workspace"
  value       = azurerm_databricks_workspace.databricks.workspace_url
}
