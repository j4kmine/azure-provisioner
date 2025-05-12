variable "name" {
  description = "The name of the Cosmos DB account"
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

variable "offer_type" {
  description = "The Cosmos DB account offer type"
  type        = string
  default     = "Standard"
}

variable "kind" {
  description = "The kind of Cosmos DB to create"
  type        = string
  default     = "MongoDB"
}

variable "consistency_level" {
  description = "The consistency level of the Cosmos DB account"
  type        = string
  default     = "Session"
}

variable "databases" {
  description = "The Cosmos DB databases to create"
  type        = list(map(any))
  default     = []
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}

resource "azurerm_cosmosdb_account" "cosmos" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = var.offer_type
  kind                = var.kind
  tags                = var.tags

  consistency_policy {
    consistency_level = var.consistency_level
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableMongo"
  }
}

resource "azurerm_cosmosdb_mongo_database" "database" {
  for_each            = { for db in var.databases : db.name => db }
  name                = each.value.name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  throughput          = lookup(each.value, "throughput", 400)
}

resource "azurerm_cosmosdb_mongo_collection" "collection" {
  for_each = {
    for idx, collection in flatten([
      for db in var.databases : [
        for collection in lookup(db, "collections", []) : {
          db_name          = db.name
          collection_name  = collection.name
          partition_key    = collection.partition_key_path
          throughput       = lookup(collection, "throughput", null)
          shard_key        = lookup(collection, "shard_key", null)
        }
      ]
    ]) : "${collection.db_name}-${collection.collection_name}" => collection
  }

  name                = each.value.collection_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = each.value.db_name
  throughput          = each.value.throughput

  # MongoDB collections require a shard key
  index {
    keys   = ["_id"]
    unique = true
  }

  # Additional index for the partition key
  index {
    keys   = [substr(each.value.partition_key, 1, -1)] # Remove the leading "/"
    unique = false
  }
}

output "cosmos_db_id" {
  description = "The ID of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.cosmos.id
}

output "cosmos_db_name" {
  description = "The name of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.cosmos.name
}

output "cosmos_db_endpoint" {
  description = "The endpoint of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.cosmos.endpoint
}

output "cosmos_db_primary_key" {
  description = "The primary key of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.cosmos.primary_key
  sensitive   = true
}
