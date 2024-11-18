param location string
param vmx1Id string
param vmx2Id string

resource loadBalancer 'Microsoft.Network/loadBalancers@2021-05-01' = {
  name: 'vmx-lb'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: []
    backendAddressPools: [
      {
        name: 'vmxBackendPool'
        properties: {
          loadBalancerBackendAddresses: [
            {
              name: 'vmx1'
              properties: {
                virtualMachine: {
                  id: vmx1Id
                }
              }
            }
            {
              name: 'vmx2'
              properties: {
                virtualMachine: {
                  id: vmx2Id
                }
              }
            }
          ]
        }
      }
    ]
  }
}

output lbId string = loadBalancer.id 
