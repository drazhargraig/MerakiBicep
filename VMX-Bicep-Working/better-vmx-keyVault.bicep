param location string
param virtualNetworkName string
param virtualNetworkAddressPrefix string
param virtualNetworkNewOrExisting string
param subnet1Name string
param subnet1AddressPrefix string
param subnet2Name string
param subnet2AddressPrefix string
param zone string
param virtualNetworkResourceGroup string
param virtualMachineSize string
param applicationResourceName string
param keyVaultName string
param keyVaultResourceGroup string
param vmName string

// This parameter can stay in the bicep file as it's dynamically generated
param managedResourceGroupId string = '${subscription().id}/resourceGroups/${take('${resourceGroup().name}-${uniqueString(resourceGroup().id)}${uniqueString(applicationResourceName)}', 90)}'

// Step 1: Create the Virtual Network with 2 Subnets
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1AddressPrefix
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2AddressPrefix
        }
      }
    ]
  }
}

// Step 1: Create User Assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${applicationResourceName}-identity'
  location: location
}
// Assign Key Vault Administrator role to the managed identity
resource kvAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, managedIdentity.id, keyVaultName)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Deployment script with cleanup
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
        
        # Cleanup: Remove the Key Vault Administrator role
        #$roleDefinitionId = "/subscriptions/$($env:SUBSCRIPTION_ID)/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483"
        #$roleAssignmentId = "/subscriptions/$($env:SUBSCRIPTION_ID)/resourceGroups/$($env:RESOURCE_GROUP)/providers/Microsoft.Authorization/roleAssignments/$($env:MANAGED_IDENTITY_ID)"
        #Remove-AzRoleAssignment -ObjectId $env:MANAGED_IDENTITY_ID -RoleDefinitionId $roleDefinitionId -Scope $roleAssignmentId
      } catch {
        $DeploymentScriptOutputs['error'] = $_.Exception.Message
      }
    '''
    timeout: 'PT10M'
  }
}

// Step 3: Deploy the Cisco Meraki vMX Appliance using the Token
resource vmx 'Microsoft.Solutions/applications@2017-09-01' = {
  name: applicationResourceName
  location: resourceGroup().location
  kind: 'MarketPlace'
  plan: {
    name: 'cisco-meraki-vmx'
    product: 'cisco-meraki-vmx'
    publisher: 'cisco'
    version: '15.37.4'
  }
  properties: {
    managedResourceGroupId: managedResourceGroupId
    parameters: {
      location: {
        value: location
      }
      vmName: {
        value: vmName
      }
      merakiAuthToken: {
        value: script.properties.outputs.merakiAuthToken
      }
      zone: {
        value: zone
      }
      virtualNetworkName: {
        value: virtualNetworkName
      }
      virtualNetworkAddressPrefix: {
        value: virtualNetworkAddressPrefix
      }
      virtualNetworkNewOrExisting: {
        value: virtualNetworkNewOrExisting
      }
      virtualNetworkResourceGroup: {
        value: virtualNetworkResourceGroup
      }
      virtualMachineSize: {
        value: virtualMachineSize
      }
      subnetName: {
        value: subnet1Name
      }
      subnetAddressPrefix: {
        value: subnet1AddressPrefix
      }
    }
  }
}
