import click
from jinja2 import Environment, FileSystemLoader, Template
import os
import yaml


class JinjaTFTemplate:

    CONFIG_FOLDER: str = "/workspace/configs"
    TEMPLATE_FOLDER: str = "/workspace/azure_provisioner/templates"
    ENVIRONMENT_FOLDER: str = "/workspace/azure_provisioner/environments"
    TEMPLATE_FILES: list = ["main.tf", "backend.tf", "provider.tf", "variables.tf"]

    def __init__(self, project_id: str, ecosystem: str) -> None:
        self.project_id: str = project_id
        self.ecosystem: str = ecosystem
        self.environment: Environment = Environment(loader=FileSystemLoader(JinjaTFTemplate.TEMPLATE_FOLDER))
        self.config_path = f"{JinjaTFTemplate.CONFIG_FOLDER}/{self.ecosystem}/{self.project_id}.yaml"
        with open(self.config_path, "r") as file:
            file_content: str = file.read()
        self.state_config: dict = yaml.safe_load(file_content)
        if "terraform_state_storage_account" not in self.state_config:
            self.state_config["terraform_state_storage_account"] = f"{self.state_config['ecosystem']}tf{self.state_config['environment']}"
    
    def generate_files(self) -> None:
        for file in JinjaTFTemplate.TEMPLATE_FILES:
            template_file: Template = self.environment.get_template(f"{file}.j2")
            content: str = template_file.render(self.state_config)
            output_folder: str = f"{JinjaTFTemplate.ENVIRONMENT_FOLDER}/{self.project_id}"
            output_path: str = f"{output_folder}/{file}"

            # Create folder if not exists
            if not os.path.exists(output_folder):
                print(f"Creating folder '{output_folder}'...")
                os.makedirs(f"{output_folder}")

            with open(output_path, mode="w", encoding="utf-8") as file:
                file.write(content)
                print(f"Generating file {output_path}...")


@click.group()
def cli(): pass


@cli.command()
@click.option("--project", type=str, required=True)
@click.option("--ecosystem", type=str, required=True)
def generate_tf_files(project: str, ecosystem: str):
    tf_template: JinjaTFTemplate = JinjaTFTemplate(project_id=project, ecosystem=ecosystem)
    tf_template.generate_files()

if __name__ == "__main__": cli()
