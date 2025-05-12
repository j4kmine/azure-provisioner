variable "name" {
  description = "The name of the Log Analytics workspace"
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
  description = "The SKU of the Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "The retention period in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}

resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

output "log_analytics_id" {
  description = "The ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.log_analytics.id
}

output "log_analytics_name" {
  description = "The name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.log_analytics.name
}

output "log_analytics_primary_shared_key" {
  description = "The primary shared key of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.log_analytics.primary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "The workspace ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.log_analytics.workspace_id
}
