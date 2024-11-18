# Azure Bicep Deployment Versions

This repository contains different versions of Azure infrastructure deployments using Bicep, a domain-specific language (DSL) for deploying Azure resources.

## Table of Contents
- [Directory Structure](#directory-structure)
- [Usage](#usage)
- [Deployment Instructions](#deployment-instructions)
- [Contribution Guidelines](#contribution-guidelines)

## Directory Structure

### /Old
Initial version of the Bicep deployment templates. Contains basic infrastructure setup.

### /VMX-ARM

Exported Azure JSON ARM template from Azure Portal.

### /VMX-Bicep-Working

Enhanced version with additional resources and improved modularity.

### /VMX-Bicep-Hard-Coded-Params
Latest version with full infrastructure deployment including:
- Resource organization
- Advanced configurations
- Best practices implementation

## Usage

Each version folder contains its own:
- Main deployment file (`main.bicep`)
- Supporting modules
- Parameter files
- Documentation specific to that version

## Deployment Instructions
To deploy a specific version, navigate to the desired folder and run the deployment command using the Bicep CLI or Azure CLI.

## Contribution Guidelines
We welcome contributions! Please fork the repository and submit a pull request with your changes.
