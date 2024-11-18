# VMX Uniphar Production Deployment

This repository contains the Infrastructure as Code (IaC) templates for deploying Cisco Meraki vMX appliances in both test and production environments.

## Environment Structure
- **Production**: Dual VMX appliances with load balancer
- **Test**: Single VMX appliance

## Summary of Code Functionality

The Bicep templates in this repository automate the deployment of Cisco Meraki vMX appliances in Azure. The deployment includes the following components:

1. **Resource Groups**: Creates necessary resource groups for the deployment.
2. **Virtual Network**: Sets up a virtual network with specified subnets.
3. **User Assigned Managed Identity**: Creates a managed identity for accessing Azure resources securely.
4. **Key Vault Role Assignment**: Assigns the necessary permissions to the managed identity to access secrets in Azure Key Vault.
5. **Deployment Script**: Executes a script to retrieve the Meraki authentication token from the Key Vault.
6. **VMX Appliance**: Deploys the Cisco Meraki vMX appliance using the retrieved authentication token.

## Deployment Instructions

The deployment depends on the following existing resources in your Azure subscription:

1. **Resource Groups**:
   - A resource group for the Key Vault (specified in the parameters).
   - A resource group for the virtual network (specified in the parameters).
   - A resource group for the VMX appliance (specified in the parameters).

2. **Key Vault**:
   - A Key Vault must exist in the specified resource group, containing the following secrets:
     - `apiAuthKey`: The API key for accessing the Cisco Meraki API.
     - `testvmxSerial`: The serial number of the VMX appliance to be deployed.

3. **Network Connectivity**:
   - Ensure that the network connectivity requirements are met for the VMX appliance to function correctly.

### Test Environment

To deploy the test environment, use the following PowerShell command:

\\\powershell
New-AzResourceGroupDeployment 
  -Name "vmx-test-deployment" 
  -ResourceGroupName "rg-vmx-test" 
  -TemplateFile "./environments/test/main.bicep" 
  -TemplateParameterFile "./environments/test/main.parameters.json"
\\\

### Production Environment

To deploy the production environment, use the following PowerShell command:

\\\powershell
New-AzResourceGroupDeployment 
  -Name "vmx-prod-deployment" 
  -ResourceGroupName "rg-vmx-prod" 
  -TemplateFile "./environments/prod/main.bicep" 
  -TemplateParameterFile "./environments/prod/main.parameters.json"
\\\

## Prerequisites
- Azure subscription
- Required resource groups created
- Key Vault with necessary secrets
- Network connectivity requirements met

## Additional Notes
- Ensure that the parameters in the `main.parameters.json` file are correctly set to match your Azure environment.
- Review the Bicep modules in the `modules` directory for more details on the resources being deployed.
