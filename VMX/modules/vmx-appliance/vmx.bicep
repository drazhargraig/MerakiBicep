param location string
param vnetName string
param vmName string
param virtualMachineSize string
param zone string
param merakiAuthToken string
param managedResourceGroupId string
param applicationResourceName string
param virtualNetworkNewOrExisting string
param virtualNetworkResourceGroup string
param virtualNetworkAddressPrefix string
param subnet1Name string
param subnet1AddressPrefix string

resource vmx 'Microsoft.Solutions/applications@2017-09-01' = {
  name: applicationResourceName
  location: location
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
        value: merakiAuthToken
      }
      zone: {
        value: zone
      }
      virtualNetworkName: {
        value: vnetName
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

output vmxId string = vmx.id
