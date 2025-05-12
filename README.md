# Azure Provisioner

Infrastructure as Code (IaC) tool to provision Azure Data Factory and related infrastructure using Terraform.

## Overview

This project provides a streamlined way to deploy and manage Azure Data Factory environments and related Azure services. It uses YAML configuration files to define the desired infrastructure state and generates Terraform files that provision the infrastructure.

## Features

- **Azure Data Factory**: Create and configure Azure Data Factory instances, including linked services, datasets, pipelines, and triggers
- **Azure Synapse Analytics**: Deploy and configure Synapse workspaces, SQL pools, and Spark pools
- **Supporting Infrastructure**: Provision required supporting resources such as:
  - Storage Accounts
  - Key Vaults
  - SQL Servers and Databases
  - Resource Groups
- **CI/CD Integration**: Support for Azure DevOps pipelines

## Requirements

- Docker (for containerized deployment)
- Azure CLI (for local development)
- Python 3.8+ (for local development)
- Terraform 1.0+ (for local development)

## Getting Started

### Setup Terraform State Backend

Before you can deploy resources, you need to set up a storage account to store the Terraform state:

```bash
make azure_login
make azure_create_tf_storage project_id=your-project-id ecosystem=your-ecosystem env=dev
```

### Generate Terraform Files

Create a YAML configuration file in the `configs/your-ecosystem/` directory named `your-project-id.yaml`. Use the example config as a template. Then generate the Terraform files:

```bash
make hcl_generate project_id=your-project-id ecosystem=your-ecosystem
```

### Deploy Infrastructure

Initialize, plan, and apply the Terraform configuration:

```bash
make tf_init project_id=your-project-id
make tf_plan project_id=your-project-id
make tf_apply project_id=your-project-id
```

## Configuration Reference

### Example Configuration

See the `configs/example-config.yaml` file for a complete example of configuring:

- Azure Data Factory
- Storage Accounts
- Key Vault
- SQL Server
- Synapse Analytics

### Project Structure

- `azure_provisioner/`: Core Python package
  - `modules/`: Terraform modules for Azure resources
  - `templates/`: Jinja2 templates for Terraform files
  - `environments/`: Generated Terraform configurations
- `configs/`: YAML configuration files
- `docker/`: Docker build configurations
- `Makefile`: Commands for building and deploying

## Development

### Building the Package

```bash
make build
```

### Running Tests

```bash
make test_pyflakes
```


