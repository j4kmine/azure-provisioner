variable "name" {
  description = "The name of the key vault"
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

variable "sku_name" {
  description = "The name of the SKU used for this Key Vault"
  type        = string
  default     = "standard"
}

variable "soft_delete_retention_days" {
  description = "The number of days that items should be retained for once soft-deleted"
  type        = number
  default     = 7
}

variable "purge_protection_enabled" {
  description = "Is Purge Protection enabled for this Key Vault?"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Is Disk Encryption enabled for this Key Vault?"
  type        = bool
  default     = false
}

variable "secrets" {
  description = "Secrets to create in the key vault"
  type        = list(map(string))
  default     = []
}

variable "access_policies" {
  description = "Access policies for the key vault"
  type        = list(map(string))
  default     = []
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}

resource "azurerm_key_vault" "vault" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = var.enabled_for_disk_encryption
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = var.soft_delete_retention_days
  purge_protection_enabled    = var.purge_protection_enabled
  sku_name                    = var.sku_name
  tags                        = var.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_access_policy" "policy" {
  count        = length(var.access_policies)
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.access_policies[count.index].object_id

  secret_permissions = lookup(var.access_policies[count.index], "secret_permissions", [])
  key_permissions    = lookup(var.access_policies[count.index], "key_permissions", [])
  certificate_permissions = lookup(var.access_policies[count.index], "certificate_permissions", [])
}

resource "azurerm_key_vault_secret" "secret" {
  count        = length(var.secrets)
  name         = var.secrets[count.index].name
  value        = var.secrets[count.index].value
  key_vault_id = azurerm_key_vault.vault.id
  
  depends_on = [azurerm_key_vault_access_policy.policy]
}

output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.vault.id
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.vault.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.vault.vault_uri
}
