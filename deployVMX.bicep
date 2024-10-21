param location string
param vmName string
param merakiAuthToken string
param zone string = '0'
param virtualNetworkName string
param virtualNetworkNewOrExisting string
param virtualNetworkAddressPrefix string
param virtualNetworkResourceGroup string
param virtualMachineSize string
param subnetName string
param subnetAddressPrefix string
param applicationResourceName string = 'afa46c364ad942ca86815adf61e82c5a'
param managedResourceGroupId string = ''
param managedIdentity object = {}

var managedResourceGroupId = empty(managedResourceGroupId) ? 
  '${subscription().id}/resourceGroups/${take(resourceGroup().name, uniquestring(resourceGroup().id, applicationResourceName), 90)}' : managedResourceGroupId

resource merakiVMX 'Microsoft.Solutions/applications@2017-09-01' = {
  name: applicationResourceName
  location: resourceGroup().location
  kind: 'MarketPlace'
  plan: {
    name: 'cisco-meraki-vmx'
    product: 'cisco-meraki-vmx'
    publisher: 'cisco'
    version: '15.37.4'
  }
  identity: empty(managedIdentity) ? null : managedIdentity
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
        value: virtualNetworkName
      }
      virtualNetworkNewOrExisting: {
        value: virtualNetworkNewOrExisting
      }
      virtualNetworkAddressPrefix: {
        value: virtualNetworkAddressPrefix
      }
      virtualNetworkResourceGroup: {
        value: virtualNetworkResourceGroup
      }
      virtualMachineSize: {
        value: virtualMachineSize
      }
      subnetName: {
        value: subnetName
      }
      subnetAddressPrefix: {
        value: subnetAddressPrefix
      }
    }
    jitAccessPolicy: null
  }
}
