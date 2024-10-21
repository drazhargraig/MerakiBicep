param location string = 'northeurope'
param virtualNetworkName string = 'vnet-jp-vmxtest-neu-01'
param virtualNetworkAddressPrefix string = '172.16.0.0/28'
param virtualNetworkNewOrExisting string = 'existing'
param subnet1Name string = 'snet-vmx-subnet1'
param subnet1AddressPrefix string = '172.16.0.0/29'
param subnet2Name string = 'snet-vmx-subnet2'
param subnet2AddressPrefix string = '172.16.0.8/29'
param apiAuthKey string = '895e84e16c1d05d9f53b004cb4aacbafa8f1cf1f'
param orgId string = '3861836680470200390'
param vmxSerial string = 'Q2BZ-DD3U-TDJF'
param vmName string = 'vmx-jp-neu'
param zone string = '0'
param virtualNetworkResourceGroup string = 'jp-rg-ne-001'
param virtualMachineSize string = 'Standard_F4s_v2'
param applicationResourceName string = 'vmxdevneu'
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

// Step 2: Inline Script to Retrieve Meraki Authentication Token
// There are no Input Parameters to this, as the production script will call from Key Vault
resource script 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'getMerakiAuthToken'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '3.0'
    retentionInterval: 'P1D'
    scriptContent: '''
    $DeploymentScriptOutputs = @{}
    
    $headers = @{
      "X-Cisco-Meraki-API-Key" = '895e84e16c1d05d9f53b004cb4aacbafa8f1cf1f'
    }
    $serial = 'Q2BZ-DD3U-TDJF'
    $uri = "https://api.meraki.com/api/v1/devices/$serial/appliance/vmx/authenticationToken"
    
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
    
    $DeploymentScriptOutputs['merakiAuthToken'] = $response.token
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
