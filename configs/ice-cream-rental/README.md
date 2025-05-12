# Ice Cream Truck Rental Data Pipeline

This project provisions a comprehensive Azure data pipeline that processes, analyzes, and visualizes data to support ice cream truck rental business decisions across Europe.

## Business Case

Our client wants to rent out ice cream trucks across Europe and needs data-driven insights to:

1. **Analyze weather-to-sales correlation** - Understand how weather impacts ice cream sales by region
2. **Determine optimal main location** - Identify the best country for a headquarters
3. **Calculate revenue vs. rent ratio** - Analyze where rental operations would be most profitable
4. **Perform ROI analysis** - Use ice cream prices and Big Mac Index to determine strongest ROI
5. **Plan optimal country pattern** - Create a route plan for trucks to maximize profitability

## Architecture Overview

![Ice Cream Rental Data Pipeline Architecture](architecture-diagram.png)

### Data Sources
- **Weather API** - Real-time and historical weather data from OpenWeatherMap
- **Sales Data** - Ice cream sales data stored in Azure SQL Database
- **Reference Data** - CSV/JSON files in Azure Blob Storage containing:
  - Big Mac Index by country
  - Truck rental prices by country
  - Diesel prices by country
  - Ice cream price averages

### Data Processing Flow
1. **Data Ingestion**
   - Azure Data Factory pipelines fetch data from all sources
   - Raw data is stored in Data Lake Storage Gen2

2. **Data Processing**
   - Azure Databricks performs complex transformations (weather correlation, ROI calculations)
   - Data Factory handles orchestration and simpler transformations
   - Synapse Analytics provides SQL-based analysis capabilities

3. **Data Storage**
   - Processed data stored in Data Lake Storage Gen2 (Delta format)
   - Analytics results in Azure SQL Database
   - Weather data in Cosmos DB for fast queries

4. **Analytics & Visualization**
   - Power BI reports for business insights
   - Monitoring dashboards for pipeline health

### Monitoring & Error Handling
- Application Insights tracks custom metrics
- Log Analytics collects all system and application logs
- Alerts configured for critical pipeline failures
- Error handling with retry policies and error data storage

## Infrastructure Resources

The following Azure resources are provisioned for this solution:

- **Resource Group**: `rg-ice-cream-rental-dev`
- **Key Vault**: `kv-ice-cream-rental-dev` - Securely stores all credentials and secrets
- **Storage Account**: `stgicecreamrentaldev` - Data Lake Storage Gen2 with hierarchical namespace
- **SQL Server**: `sql-ice-cream-rental-dev` - Hosts sales and analytics databases
- **Cosmos DB**: `cosmos-ice-cream-rental-dev` - Stores weather data and forecasts
- **Data Factory**: `adf-ice-cream-rental-dev` - Orchestrates the entire data pipeline
- **Databricks Workspace**: `dbw-ice-cream-rental-dev` - Handles complex data transformations
- **Synapse Workspace**: `syn-ice-cream-rental-dev` - Provides SQL and Spark analytics capabilities
- **Application Insights**: `appi-ice-cream-rental-dev` - Application monitoring
- **Log Analytics Workspace**: `law-ice-cream-rental-dev` - Centralized logging

## Deployment Instructions

1. **Set up Azure Authentication**:
   ```bash
   make azure_login
   make azure_set_subscription subscription=your-subscription-id
   ```

2. **Create Terraform State Storage**:
   ```bash
   make azure_create_tf_storage project_id=ice-cream-rental ecosystem=data-pipeline env=dev
   ```

3. **Set up Key Vault and Secrets**:
   ```bash
   make azure_create_key_vault project_id=ice-cream-rental ecosystem=data-pipeline env=dev
   make azure_set_key_vault_secret project_id=ice-cream-rental ecosystem=data-pipeline env=dev name=sql-admin-password value=your-secure-password
   make azure_set_key_vault_secret project_id=ice-cream-rental ecosystem=data-pipeline env=dev name=weather-api-key value=your-api-key
   ```

4. **Generate Terraform Files**:
   ```bash
   make hcl_generate project_id=ice-cream-rental ecosystem=data-pipeline
   ```

5. **Deploy Infrastructure**:
   ```bash
   make tf_init project_id=ice-cream-rental
   make tf_plan project_id=ice-cream-rental
   make tf_apply project_id=ice-cream-rental
   ```

## Post-Deployment Setup

After deploying the infrastructure, the following manual steps are required:

1. **Upload Reference Data Files**:
   - Upload Big Mac Index, truck rental prices, and ice cream price CSVs to the `reference` container

2. **Configure Data Factory Pipelines**:
   - Deploy the pipeline templates in the Git repository
   - Set up OpenWeatherMap API connections

3. **Deploy Databricks Notebooks**:
   - Import the transformation notebooks
   - Configure cluster parameters

4. **Set up Power BI Reports**:
   - Connect to the data sources
   - Deploy the provided report templates

## Monitoring & Maintenance

- **Pipeline Monitoring**: View the Data Factory monitoring dashboard
- **Log Analytics**: Query logs for errors and performance issues
- **Alerts**: Configured for pipeline failures, data quality issues, and performance thresholds

## Data Pipeline Schedule

- **Weather Data**: Updated hourly
- **Sales Data**: Processed daily
- **Reference Data**: Updated monthly (Big Mac Index, rental prices)
- **Analytics**: Full refresh nightly
