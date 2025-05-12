variable "name" {
  description = "The name of the SQL Server"
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

variable "version" {
  description = "The version for the SQL Server"
  type        = string
  default     = "12.0"
}

variable "administrator_login" {
  description = "The administrator login for the SQL Server"
  type        = string
}

variable "administrator_login_password_key_vault_name" {
  description = "The name of the Key Vault containing the administrator login password secret"
  type        = string
}

variable "administrator_login_password_key_vault_secret_name" {
  description = "The name of the Key Vault secret containing the administrator login password"
  type        = string
}

variable "databases" {
  description = "The SQL databases to create"
  type        = list(map(string))
  default     = []
}

variable "firewall_rules" {
  description = "The firewall rules for the SQL Server"
  type        = list(map(string))
  default     = []
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}

data "azurerm_key_vault" "kv" {
  name                = var.administrator_login_password_key_vault_name
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault_secret" "admin_password" {
  name         = var.administrator_login_password_key_vault_secret_name
  key_vault_id = data.azurerm_key_vault.kv.id
}

resource "azurerm_mssql_server" "server" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.version
  administrator_login          = var.administrator_login
  administrator_login_password = data.azurerm_key_vault_secret.admin_password.value
  tags                         = var.tags
  
  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = data.azurerm_client_config.current.object_id
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_mssql_database" "db" {
  count                = length(var.databases)
  name                 = var.databases[count.index].name
  server_id            = azurerm_mssql_server.server.id
  sku_name             = lookup(var.databases[count.index], "sku_name", "S0")
  max_size_gb          = lookup(var.databases[count.index], "max_size_gb", 2)
  collation            = lookup(var.databases[count.index], "collation", "SQL_Latin1_General_CP1_CI_AS")
  zone_redundant       = lookup(var.databases[count.index], "zone_redundant", false)
  read_scale           = lookup(var.databases[count.index], "read_scale", false)
  read_replica_count   = lookup(var.databases[count.index], "read_replica_count", 0)
  tags                 = var.tags
}

resource "azurerm_mssql_firewall_rule" "fw_rule" {
  count            = length(var.firewall_rules)
  name             = var.firewall_rules[count.index].name
  server_id        = azurerm_mssql_server.server.id
  start_ip_address = var.firewall_rules[count.index].start_ip_address
  end_ip_address   = var.firewall_rules[count.index].end_ip_address
}

output "sql_server_id" {
  description = "The ID of the SQL Server"
  value       = azurerm_mssql_server.server.id
}

output "sql_server_name" {
  description = "The name of the SQL Server"
  value       = azurerm_mssql_server.server.name
}

output "sql_server_fqdn" {
  description = "The fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.server.fully_qualified_domain_name
}

output "sql_databases" {
  description = "Information about the SQL databases"
  value = {
    for db in azurerm_mssql_database.db :
    db.name => {
      id   = db.id
      name = db.name
    }
  }
}
