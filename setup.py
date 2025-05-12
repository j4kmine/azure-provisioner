import os
from setuptools import setup, find_packages

# Read version from environment variable
build_version = os.environ.get("build_version", "1.0.0")

setup(
    name="azure_provisioner",
    version=build_version,
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        "click>=8.0.0",
        "jinja2>=3.0.0",
        "pyyaml>=6.0",
    ],
    entry_points={
        'console_scripts': [
            'azure_provisioner=azure_provisioner.entrypoint:cli',
        ],
    },
    author="Data Engineering Team",
    author_email="data-engineering@example.com",
    description="Provisioning tool for Azure Data Factory and related services",
    keywords="azure, terraform, data factory, provisioning",
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
    ],
    python_requires=">=3.8",
)
