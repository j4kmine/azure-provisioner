variable "name" {
  description = "The name of the Azure Data Factory"
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

variable "managed_virtual_network_enabled" {
  description = "Enable managed virtual network for the Data Factory"
  type        = bool
  default     = true
}

variable "public_network_enabled" {
  description = "Enable public network access for the Data Factory"
  type        = bool
  default     = true
}

variable "github_configuration" {
  description = "GitHub repository configuration for the Data Factory"
  type        = map(string)
  default     = {}
}

variable "linked_services" {
  description = "Linked services for the Data Factory"
  type        = list(map(string))
  default     = []
}

variable "integration_runtimes" {
  description = "Integration runtimes for the Data Factory"
  type        = list(map(string))
  default     = []
}

variable "pipelines" {
  description = "Pipelines for the Data Factory"
  type        = list(map(string))
  default     = []
}

variable "datasets" {
  description = "Datasets for the Data Factory"
  type        = list(map(string))
  default     = []
}

variable "data_flows" {
  description = "Data flows for the Data Factory"
  type        = list(map(string))
  default     = []
}

variable "triggers" {
  description = "Triggers for the Data Factory"
  type        = list(map(string))
  default     = []
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}

# Azure Data Factory
resource "azurerm_data_factory" "adf" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  managed_virtual_network_enabled = var.managed_virtual_network_enabled
  public_network_enabled          = var.public_network_enabled
  tags                            = var.tags

  dynamic "github_configuration" {
    for_each = length(var.github_configuration) > 0 ? [1] : []
    content {
      account_name    = var.github_configuration["account_name"]
      branch_name     = var.github_configuration["branch_name"]
      git_url         = var.github_configuration["git_url"]
      repository_name = var.github_configuration["repository_name"]
      root_folder     = var.github_configuration["root_folder"]
    }
  }
}

# Azure Data Factory Linked Services
resource "azurerm_data_factory_linked_service_key_vault" "key_vault_linked" {
  for_each = {
    for idx, svc in var.linked_services : idx => svc
    if svc.type == "AzureKeyVault"
  }

  name                     = each.value.name
  data_factory_id          = azurerm_data_factory.adf.id
  key_vault_id             = each.value.key_vault_id
  description              = lookup(each.value, "description", null)
  integration_runtime_name = lookup(each.value, "integration_runtime_name", null)
}

resource "azurerm_data_factory_linked_service_sql_server" "sql_server_linked" {
  for_each = {
    for idx, svc in var.linked_services : idx => svc
    if svc.type == "SqlServer"
  }

  name                     = each.value.name
  data_factory_id          = azurerm_data_factory.adf.id
  connection_string        = each.value.connection_string
  description              = lookup(each.value, "description", null)
  integration_runtime_name = lookup(each.value, "integration_runtime_name", null)
  
  key_vault_password {
    linked_service_name = lookup(each.value, "key_vault_linked_service_name", null)
    secret_name         = lookup(each.value, "password_secret_name", null)
  }
}

resource "azurerm_data_factory_linked_service_azure_blob_storage" "blob_storage_linked" {
  for_each = {
    for idx, svc in var.linked_services : idx => svc
    if svc.type == "AzureBlobStorage"
  }

  name                     = each.value.name
  data_factory_id          = azurerm_data_factory.adf.id
  connection_string        = each.value.connection_string
  description              = lookup(each.value, "description", null)
  integration_runtime_name = lookup(each.value, "integration_runtime_name", null)
}

resource "azurerm_data_factory_linked_service_azure_sql_database" "sql_db_linked" {
  for_each = {
    for idx, svc in var.linked_services : idx => svc
    if svc.type == "AzureSqlDatabase"
  }

  name                     = each.value.name
  data_factory_id          = azurerm_data_factory.adf.id
  connection_string        = each.value.connection_string
  description              = lookup(each.value, "description", null)
  integration_runtime_name = lookup(each.value, "integration_runtime_name", null)
  
  key_vault_password {
    linked_service_name = lookup(each.value, "key_vault_linked_service_name", null)
    secret_name         = lookup(each.value, "password_secret_name", null)
  }
}

# Azure Data Factory Integration Runtimes
resource "azurerm_data_factory_integration_runtime_azure" "azure_ir" {
  for_each = {
    for idx, ir in var.integration_runtimes : idx => ir
    if ir.type == "Azure"
  }

  name                    = each.value.name
  data_factory_id         = azurerm_data_factory.adf.id
  location                = lookup(each.value, "location", "AutoResolve")
  description             = lookup(each.value, "description", null)
  compute_type            = lookup(each.value, "compute_type", "General")
  core_count              = lookup(each.value, "core_count", 8)
  time_to_live_min        = lookup(each.value, "time_to_live_min", 0)
}

resource "azurerm_data_factory_integration_runtime_self_hosted" "self_hosted_ir" {
  for_each = {
    for idx, ir in var.integration_runtimes : idx => ir
    if ir.type == "SelfHosted"
  }

  name                    = each.value.name
  data_factory_id         = azurerm_data_factory.adf.id
  description             = lookup(each.value, "description", null)
}

# Azure Data Factory Pipelines
resource "azurerm_data_factory_pipeline" "pipeline" {
  for_each = {
    for idx, pipeline in var.pipelines : idx => pipeline
  }

  name                = each.value.name
  data_factory_id     = azurerm_data_factory.adf.id
  description         = lookup(each.value, "description", null)
  annotations         = lookup(each.value, "annotations", [])
  parameters          = lookup(each.value, "parameters", {})
  variables           = lookup(each.value, "variables", {})
  
  dynamic "activities_json" {
    for_each = lookup(each.value, "activities_json", null) != null ? [1] : []
    content {
      content = each.value.activities_json
    }
  }
}

# Azure Data Factory Triggers
resource "azurerm_data_factory_trigger_schedule" "schedule_trigger" {
  for_each = {
    for idx, trigger in var.triggers : idx => trigger
    if trigger.type == "Schedule"
  }

  name                = each.value.name
  data_factory_id     = azurerm_data_factory.adf.id
  description         = lookup(each.value, "description", null)
  pipeline_name       = each.value.pipeline_name
  pipeline_parameters = lookup(each.value, "pipeline_parameters", {})
  annotations         = lookup(each.value, "annotations", [])
  
  schedule {
    interval  = lookup(each.value, "interval", 1)
    frequency = lookup(each.value, "frequency", "Day")
    start_time = lookup(each.value, "start_time", null)
    end_time   = lookup(each.value, "end_time", null)
    time_zone  = lookup(each.value, "time_zone", "UTC")
  }
}

output "data_factory_id" {
  description = "The ID of the Azure Data Factory"
  value       = azurerm_data_factory.adf.id
}

output "data_factory_name" {
  description = "The name of the Azure Data Factory"
  value       = azurerm_data_factory.adf.name
}
