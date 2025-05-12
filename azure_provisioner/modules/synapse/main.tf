variable "name" {
  description = "The name of the Synapse workspace"
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

variable "storage_account_name" {
  description = "The name of the storage account for the Synapse workspace"
  type        = string
}

variable "storage_container" {
  description = "The name of the storage container for the Synapse workspace"
  type        = string
  default     = "synapse"
}

variable "sql_administrator_login" {
  description = "The administrator login for the Synapse workspace"
  type        = string
}

variable "sql_administrator_login_password_key_vault_name" {
  description = "The name of the Key Vault containing the administrator login password secret"
  type        = string
}

variable "sql_administrator_login_password_key_vault_secret_name" {
  description = "The name of the Key Vault secret containing the administrator login password"
  type        = string
}

variable "managed_virtual_network_enabled" {
  description = "Is Virtual Network enabled for this Synapse workspace?"
  type        = bool
  default     = true
}

variable "sql_pools" {
  description = "The SQL pools to create in the Synapse workspace"
  type        = list(map(string))
  default     = []
}

variable "spark_pools" {
  description = "The Spark pools to create in the Synapse workspace"
  type        = list(map(any))
  default     = []
}

variable "firewall_rules" {
  description = "The firewall rules for the Synapse workspace"
  type        = list(map(string))
  default     = []
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}

data "azurerm_storage_account" "storage" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault" "kv" {
  name                = var.sql_administrator_login_password_key_vault_name
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault_secret" "admin_password" {
  name         = var.sql_administrator_login_password_key_vault_secret_name
  key_vault_id = data.azurerm_key_vault.kv.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "synapse" {
  name               = var.storage_container
  storage_account_id = data.azurerm_storage_account.storage.id
}

resource "azurerm_synapse_workspace" "synapse" {
  name                                 = var.name
  resource_group_name                  = var.resource_group_name
  location                             = var.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse.id
  sql_administrator_login              = var.sql_administrator_login
  sql_administrator_login_password     = data.azurerm_key_vault_secret.admin_password.value
  managed_virtual_network_enabled      = var.managed_virtual_network_enabled
  tags                                 = var.tags
  
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_synapse_sql_pool" "sql_pool" {
  count                = length(var.sql_pools)
  name                 = var.sql_pools[count.index].name
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  sku_name             = lookup(var.sql_pools[count.index], "sku_name", "DW100c")
  create_mode          = lookup(var.sql_pools[count.index], "create_mode", "Default")
  tags                 = var.tags
}

resource "azurerm_synapse_spark_pool" "spark_pool" {
  count                = length(var.spark_pools)
  name                 = var.spark_pools[count.index].name
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  node_size_family     = lookup(var.spark_pools[count.index], "node_size_family", "MemoryOptimized")
  node_size            = lookup(var.spark_pools[count.index], "node_size", "Small")
  tags                 = var.tags
  
  auto_scale {
    max_node_count = lookup(var.spark_pools[count.index].auto_scale, "max_node_count", 5)
    min_node_count = lookup(var.spark_pools[count.index].auto_scale, "min_node_count", 2)
  }
  
  auto_pause {
    delay_in_minutes = lookup(var.spark_pools[count.index].auto_pause, "delay_in_minutes", 15)
  }
}

resource "azurerm_synapse_firewall_rule" "fw_rule" {
  count                = length(var.firewall_rules)
  name                 = var.firewall_rules[count.index].name
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  start_ip_address     = var.firewall_rules[count.index].start_ip_address
  end_ip_address       = var.firewall_rules[count.index].end_ip_address
}

output "synapse_workspace_id" {
  description = "The ID of the Synapse workspace"
  value       = azurerm_synapse_workspace.synapse.id
}

output "synapse_workspace_name" {
  description = "The name of the Synapse workspace"
  value       = azurerm_synapse_workspace.synapse.name
}

output "synapse_workspace_connectivity_endpoints" {
  description = "A map of connectivity endpoints for the Synapse workspace"
  value       = azurerm_synapse_workspace.synapse.connectivity_endpoints
}

output "synapse_sql_pools" {
  description = "Information about the SQL pools"
  value = {
    for pool in azurerm_synapse_sql_pool.sql_pool :
    pool.name => {
      id   = pool.id
      name = pool.name
    }
  }
}

output "synapse_spark_pools" {
  description = "Information about the Spark pools"
  value = {
    for pool in azurerm_synapse_spark_pool.spark_pool :
    pool.name => {
      id   = pool.id
      name = pool.name
    }
  }
}
