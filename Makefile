# Variable validation helpers
_require_project:
ifndef project_id
	$(error project_id must be defined.)
endif

_require_email:
ifndef email
	$(error email must be defined.)
endif

_require_ecosystem:
ifndef ecosystem
	$(error ecosystem must be defined.)
endif

_require_env:
ifndef env
	$(error env must be defined.)
endif

_require_sub:
ifndef subscription
	$(error subscription must be defined.)
endif

# Build and version information
build_version := 1.0.0
docker_image := myregistry.azurecr.io/azure-provisioner/general
azure_adc_path := .azure

# Azure Authentication and Setup
azure_login:
	az login

azure_set_account: _require_email
	az account set --username $(email)

azure_set_subscription: _require_sub
	az account set --subscription $(subscription)

azure_container_registry_login:
	az acr login --name myregistry

# Azure APIs and Features
azure_enable_features:
	az feature register --namespace Microsoft.Synapse --name Workspace && \
	az feature register --namespace Microsoft.Synapse --name SQLPool && \
	az feature register --namespace Microsoft.Synapse --name SparkPool && \
	az feature register --namespace Microsoft.DataFactory --name FactoryV2 && \
	az provider register --namespace Microsoft.Synapse && \
	az provider register --namespace Microsoft.DataFactory

# Azure Storage for Terraform state
azure_create_tf_storage: _require_ecosystem _require_env
	$(eval storage_account ?= $(shell yq '.terraform_state_storage_account' configs/$(ecosystem)/$(project_id).yaml))
	$(eval resource_group ?= $(shell yq '.resource_group_name' configs/$(ecosystem)/$(project_id).yaml))
	az group create --name $(resource_group) --location eastus2 && \
	az storage account create --name $(storage_account) --resource-group $(resource_group) --location eastus2 --sku Standard_LRS && \
	az storage container create --name terraform-state --account-name $(storage_account) --auth-mode login

# Key Vault for secrets
azure_create_key_vault: _require_ecosystem _require_env
	$(eval key_vault ?= $(shell yq '.key_vaults[0].name' configs/$(ecosystem)/$(project_id).yaml))
	$(eval resource_group ?= $(shell yq '.resource_group_name' configs/$(ecosystem)/$(project_id).yaml))
	az keyvault create --name $(key_vault) --resource-group $(resource_group) --location eastus2

azure_set_key_vault_secret: _require_ecosystem _require_env
	$(eval key_vault ?= $(shell yq '.key_vaults[0].name' configs/$(ecosystem)/$(project_id).yaml))
	az keyvault secret set --vault-name $(key_vault) --name $(name) --value $(value)

# Build
build: build_wheel docker_build

build_wheel:
	build_version=$(build_version) python3 setup.py sdist bdist_wheel

docker_build:
	docker build --platform linux/amd64 \
	-f docker/general/Dockerfile \
	--build-arg build_version=$(build_version) \
	-t $(docker_image):$(build_version) .

# Tests
test_pyflakes:
	docker run --rm \
	-v $(shell pwd):/workspace \
	--entrypoint pyflakes eeacms/pyflakes:py3 /workspace/azure_provisioner

# Docker
docker_push:
	docker push $(docker_image):$(build_version)

docker_pull:
	docker pull $(docker_image):$(build_version)

# HCL files generator
hcl_generate: _require_project _require_ecosystem
	docker run --rm \
	-v $(shell pwd):/workspace \
	--entrypoint azure_provisioner $(docker_image):$(build_version) generate-tf-files \
	--project=$(project_id) \
	--ecosystem=$(ecosystem)

# Local Terraform commands
tf_init: _require_project
	docker run --rm \
	-v $(shell pwd):/workspace \
	-v $$HOME/$(azure_adc_path):/root/.azure:ro \
	--entrypoint terraform $(docker_image):$(build_version) \
	-chdir=/workspace/azure_provisioner/environments/$(project_id) init -upgrade

tf_plan: _require_project
	docker run --rm \
	-v $(shell pwd):/workspace \
	-v $$HOME/$(azure_adc_path):/root/.azure:ro \
	--entrypoint terraform $(docker_image):$(build_version) \
	-chdir=/workspace/azure_provisioner/environments/$(project_id) plan

tf_apply: _require_project
	docker run --rm \
	-v $(shell pwd):/workspace \
	-v $$HOME/$(azure_adc_path):/root/.azure:ro \
	--entrypoint terraform $(docker_image):$(build_version) \
	-chdir=/workspace/azure_provisioner/environments/$(project_id) apply -auto-approve

tf_destroy: _require_project
	docker run --rm \
	-v $(shell pwd):/workspace \
	-v $$HOME/$(azure_adc_path):/root/.azure:ro \
	--entrypoint terraform $(docker_image):$(build_version) \
	-chdir=/workspace/azure_provisioner/environments/$(project_id) destroy -auto-approve

tf_list_state: _require_project
	docker run --rm \
	-v $(shell pwd):/workspace \
	-v $$HOME/$(azure_adc_path):/root/.azure:ro \
	--entrypoint terraform $(docker_image):$(build_version) \
	-chdir=/workspace/azure_provisioner/environments/$(project_id) state list

# Azure Pipeline commands
azure_pipeline_init: _require_project
	docker run --rm \
	--network host \
	-v $(shell pwd):/workspace \
	--entrypoint terraform $(docker_image):$(build_version) \
	-chdir=/workspace/azure_provisioner/environments/$(project_id) init -upgrade

azure_pipeline_plan: _require_project
	docker run --rm \
	--network host \
	-v $(shell pwd):/workspace \
	--entrypoint terraform $(docker_image):$(build_version) \
	-chdir=/workspace/azure_provisioner/environments/$(project_id) plan

azure_pipeline_apply: _require_project
	docker run --rm \
	--network host \
	-v $(shell pwd):/workspace \
	--entrypoint terraform $(docker_image):$(build_version) \
	-chdir=/workspace/azure_provisioner/environments/$(project_id) apply -auto-approve

# Helper commands for Azure Data Factory
adf_create_linked_service: _require_project
	$(eval resource_group ?= $(shell yq '.resource_group_name' configs/$(ecosystem)/$(project_id).yaml))
	$(eval data_factory ?= $(shell yq '.data_factories[0].name' configs/$(ecosystem)/$(project_id).yaml))
	az datafactory linked-service create --resource-group $(resource_group) --factory-name $(data_factory) --linked-service-name $(name) --properties @$(properties_file)

adf_create_dataset: _require_project
	$(eval resource_group ?= $(shell yq '.resource_group_name' configs/$(ecosystem)/$(project_id).yaml))
	$(eval data_factory ?= $(shell yq '.data_factories[0].name' configs/$(ecosystem)/$(project_id).yaml))
	az datafactory dataset create --resource-group $(resource_group) --factory-name $(data_factory) --dataset-name $(name) --properties @$(properties_file)

adf_create_pipeline: _require_project
	$(eval resource_group ?= $(shell yq '.resource_group_name' configs/$(ecosystem)/$(project_id).yaml))
	$(eval data_factory ?= $(shell yq '.data_factories[0].name' configs/$(ecosystem)/$(project_id).yaml))
	az datafactory pipeline create --resource-group $(resource_group) --factory-name $(data_factory) --pipeline-name $(name) --properties @$(properties_file)

.PHONY: azure_login azure_set_account azure_set_subscription azure_container_registry_login azure_enable_features \
	azure_create_tf_storage azure_create_key_vault azure_set_key_vault_secret build_wheel docker_build test_pyflakes \
	docker_push docker_pull hcl_generate tf_init tf_plan tf_apply tf_destroy tf_list_state azure_pipeline_init \
	azure_pipeline_plan azure_pipeline_apply adf_create_linked_service adf_create_dataset adf_create_pipeline
