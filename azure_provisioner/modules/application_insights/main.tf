variable "name" {
  description = "The name of the Application Insights component"
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

variable "application_type" {
  description = "The type of Application Insights to create (web, ios, other, java, MobileCenter, Node.JS)"
  type        = string
  default     = "web"
}

variable "retention_in_days" {
  description = "The retention period in days"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}

resource "azurerm_application_insights" "app_insights" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = var.application_type
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

output "app_insights_id" {
  description = "The ID of the Application Insights component"
  value       = azurerm_application_insights.app_insights.id
}

output "app_insights_name" {
  description = "The name of the Application Insights component"
  value       = azurerm_application_insights.app_insights.name
}

output "app_insights_instrumentation_key" {
  description = "The instrumentation key of the Application Insights component"
  value       = azurerm_application_insights.app_insights.instrumentation_key
  sensitive   = true
}

output "app_insights_app_id" {
  description = "The App ID of the Application Insights component"
  value       = azurerm_application_insights.app_insights.app_id
}

output "app_insights_connection_string" {
  description = "The connection string of the Application Insights component"
  value       = azurerm_application_insights.app_insights.connection_string
  sensitive   = true
}
