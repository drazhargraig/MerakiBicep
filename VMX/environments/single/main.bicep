// Parameters
param location string
param vnetName string
param vnetResourceGroup string
param virtualNetworkAddressPrefix string
param subnet1Name string
param subnet1AddressPrefix string
param subnet2Name string
param subnet2AddressPrefix string
param virtualMachineSize string
param applicationResourceName string
param keyVaultName string
param keyVaultResourceGroup string
param vmName string
param zone string = '0'
param virtualNetworkNewOrExisting string = 'existing'

// Calculate managed resource group ID
param managedResourceGroupId string = '${subscription().id}/resourceGroups/${take('${resourceGroup().name}-${uniqueString(resourceGroup().id)}${uniqueString(applicationResourceName)}', 90)}'

module vMXresourceGroup '../../modules/resourceGroup/resourceGroup.bicep' = {
  name: 'vMX-resourceGroup'
  scope: subscription()
  params: {
    location: location
    resourceGroupName: vnetResourceGroup
  }
}

// VNET deployment
module vnet '../../modules/networking/vnet.bicep' = {
  name: 'vnetDeployment'
  dependsOn: [vMXresourceGroup]
  scope: resourceGroup(vnetResourceGroup)
  params: {
    location: location
    vnetName: vnetName
    addressPrefix: virtualNetworkAddressPrefix
    subnet1Name: subnet1Name
    subnet1AddressPrefix: subnet1AddressPrefix
    subnet2Name: subnet2Name
    subnet2AddressPrefix: subnet2AddressPrefix
  }
}

// Create User Assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${applicationResourceName}-identity'
  location: location
}

// Assign Key Vault Administrator role
resource kvAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, managedIdentity.id, keyVaultName)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Deployment script for Meraki auth token
resource script 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'getMerakiAuthToken'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '7.0'
    retentionInterval: 'P1D'
    environmentVariables: [
      {
        name: 'MANAGED_IDENTITY_ID'
        value: managedIdentity.id
      }
      {
        name: 'KEYVAULT_NAME'
        value: keyVaultName
      }
      {
        name: 'SUBSCRIPTION_ID'
        value: subscription().subscriptionId
      }
      {
        name: 'RESOURCE_GROUP'
        value: keyVaultResourceGroup
      }
    ]
    scriptContent: '''
      try {
        # Get secrets from Key Vault
        $apiKey = Get-AzKeyVaultSecret -VaultName $env:KEYVAULT_NAME -Name "apiAuthKey" -AsPlainText
        $serial = Get-AzKeyVaultSecret -VaultName $env:KEYVAULT_NAME -Name "testvmxSerial" -AsPlainText

        $headers = @{
          "X-Cisco-Meraki-API-Key" = $apiKey
        }
        
        $uri = "https://api.meraki.com/api/v1/devices/$serial/appliance/vmx/authenticationToken"
        
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
        
        $DeploymentScriptOutputs = @{}
        $DeploymentScriptOutputs['merakiAuthToken'] = $response.token
      } catch {
        $DeploymentScriptOutputs['error'] = $_.Exception.Message
      }
    '''
    timeout: 'PT10M'
  }
}

// VMX deployment
module vmx '../../modules/vmx-appliance/vmx.bicep' = {
  name: 'vmxDeployment'
  scope: resourceGroup(vnetResourceGroup)
  params: {
    location: location
    vnetName: vnetName
    vmName: vmName
    virtualMachineSize: virtualMachineSize
    zone: zone
    merakiAuthToken: script.properties.outputs.merakiAuthToken
    managedResourceGroupId: managedResourceGroupId
    applicationResourceName: applicationResourceName
    virtualNetworkNewOrExisting: virtualNetworkNewOrExisting
    virtualNetworkResourceGroup: vnetResourceGroup
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    subnet1Name: subnet1Name
    subnet1AddressPrefix: subnet1AddressPrefix
  }
} 
