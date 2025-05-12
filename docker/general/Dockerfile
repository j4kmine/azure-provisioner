FROM hashicorp/terraform:1.5.4 as terraform

FROM python:3.10-slim

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    unzip \
    gnupg \
    lsb-release \
    ca-certificates \
    git \
    make \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Copy Terraform binary from Terraform image
COPY --from=terraform /bin/terraform /usr/local/bin/terraform

# Set the working directory
WORKDIR /workspace

# Install Python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Set build arguments
ARG build_version=1.0.0

# Copy the Azure Provisioner package
COPY dist/azure_provisioner-${build_version}-py3-none-any.whl /tmp/
RUN pip install --no-cache-dir /tmp/azure_provisioner-${build_version}-py3-none-any.whl

# Configure entrypoint
ENTRYPOINT ["azure_provisioner"]
