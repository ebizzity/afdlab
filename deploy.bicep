@description('Primary region for deployment')
param primaryRegion string = 'Central US'

@description('Secondary region for deployment')
param secondaryRegion string = 'West US 2'

@description('Environment prefix for resource naming')
param environmentPrefix string = 'afd-lab'

@description('App Service Plan SKU')
param appServicePlanSku string = 'p1v3'

@description('Application Gateway SKU')
param applicationGatewaySku string = 'Standard_v2'

// Variables
var uniqueSuffix = uniqueString(resourceGroup().id)
var primaryRegionCode = 'cus'
var secondaryRegionCode = 'wus2'

// Primary Region Resources
resource primaryAppServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${environmentPrefix}-asp-${primaryRegionCode}-${uniqueSuffix}'
  location: primaryRegion
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: false
  }
}

resource primaryAppService 'Microsoft.Web/sites@2023-01-01' = {
  name: '${environmentPrefix}-app-${primaryRegionCode}-${uniqueSuffix}'
  location: primaryRegion
  properties: {
    serverFarmId: primaryAppServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      httpLoggingEnabled: true
      detailedErrorLoggingEnabled: true
    }
  }
}

resource primaryVNet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: '${environmentPrefix}-vnet-${primaryRegionCode}-${uniqueSuffix}'
  location: primaryRegion
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'appgw-subnet'
        properties: {
          addressPrefix: '10.1.1.0/24'
        }
      }
    ]
  }
}

resource primaryPublicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${environmentPrefix}-pip-appgw-${primaryRegionCode}-${uniqueSuffix}'
  location: primaryRegion
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${environmentPrefix}-appgw-${primaryRegionCode}-${uniqueSuffix}'
    }
  }
}

resource primaryAppGateway 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: '${environmentPrefix}-appgw-${primaryRegionCode}-${uniqueSuffix}'
  location: primaryRegion
  properties: {
    sku: {
      name: applicationGatewaySku
      tier: 'Standard_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: primaryVNet.properties.subnets[0].id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          publicIPAddress: {
            id: primaryPublicIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appServicePool'
        properties: {
          backendAddresses: [
            {
              fqdn: primaryAppService.properties.defaultHostName
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appServiceHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', '${environmentPrefix}-appgw-${primaryRegionCode}-${uniqueSuffix}', 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', '${environmentPrefix}-appgw-${primaryRegionCode}-${uniqueSuffix}', 'port_80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'appServiceRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', '${environmentPrefix}-appgw-${primaryRegionCode}-${uniqueSuffix}', 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', '${environmentPrefix}-appgw-${primaryRegionCode}-${uniqueSuffix}', 'appServicePool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', '${environmentPrefix}-appgw-${primaryRegionCode}-${uniqueSuffix}', 'appServiceHttpSettings')
          }
        }
      }
    ]
  }
}

// Secondary Region Resources
resource secondaryAppServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${environmentPrefix}-asp-${secondaryRegionCode}-${uniqueSuffix}'
  location: secondaryRegion
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: false
  }
}

resource secondaryAppService 'Microsoft.Web/sites@2023-01-01' = {
  name: '${environmentPrefix}-app-${secondaryRegionCode}-${uniqueSuffix}'
  location: secondaryRegion
  properties: {
    serverFarmId: secondaryAppServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      httpLoggingEnabled: true
      detailedErrorLoggingEnabled: true
    }
  }
}

resource secondaryVNet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: '${environmentPrefix}-vnet-${secondaryRegionCode}-${uniqueSuffix}'
  location: secondaryRegion
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'appgw-subnet'
        properties: {
          addressPrefix: '10.2.1.0/24'
        }
      }
    ]
  }
}

resource secondaryPublicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${environmentPrefix}-pip-appgw-${secondaryRegionCode}-${uniqueSuffix}'
  location: secondaryRegion
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${environmentPrefix}-appgw-${secondaryRegionCode}-${uniqueSuffix}'
    }
  }
}

resource secondaryAppGateway 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: '${environmentPrefix}-appgw-${secondaryRegionCode}-${uniqueSuffix}'
  location: secondaryRegion
  properties: {
    sku: {
      name: applicationGatewaySku
      tier: 'Standard_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: secondaryVNet.properties.subnets[0].id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          publicIPAddress: {
            id: secondaryPublicIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appServicePool'
        properties: {
          backendAddresses: [
            {
              fqdn: secondaryAppService.properties.defaultHostName
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appServiceHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', '${environmentPrefix}-appgw-${secondaryRegionCode}-${uniqueSuffix}', 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', '${environmentPrefix}-appgw-${secondaryRegionCode}-${uniqueSuffix}', 'port_80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'appServiceRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', '${environmentPrefix}-appgw-${secondaryRegionCode}-${uniqueSuffix}', 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', '${environmentPrefix}-appgw-${secondaryRegionCode}-${uniqueSuffix}', 'appServicePool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', '${environmentPrefix}-appgw-${secondaryRegionCode}-${uniqueSuffix}', 'appServiceHttpSettings')
          }
        }
      }
    ]
  }
}

// Regional Traffic Manager (for App Gateways)
resource regionalTrafficManager 'Microsoft.Network/trafficmanagerprofiles@2022-04-01' = {
  name: '${environmentPrefix}-tm-regional-${uniqueSuffix}'
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Priority'
    dnsConfig: {
      relativeName: '${environmentPrefix}-tm-regional-${uniqueSuffix}'
      ttl: 30
    }
    monitorConfig: {
      protocol: 'HTTP'
      port: 80
      path: '/'
      intervalInSeconds: 30
      timeoutInSeconds: 10
      toleratedNumberOfFailures: 3
    }
    endpoints: [
      {
        name: 'primary-appgw-endpoint'
        type: 'Microsoft.Network/trafficManagerProfiles/ExternalEndpoints'
        properties: {
          target: primaryPublicIP.properties.dnsSettings.fqdn
          endpointStatus: 'Enabled'
          priority: 1
        }
      }
      {
        name: 'secondary-appgw-endpoint'
        type: 'Microsoft.Network/trafficManagerProfiles/ExternalEndpoints'
        properties: {
          target: secondaryPublicIP.properties.dnsSettings.fqdn
          endpointStatus: 'Enabled'
          priority: 2
        }
      }
    ]
  }
}

// Azure Front Door Profile
resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: '${environmentPrefix}-afd-${uniqueSuffix}'
  location: 'global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
  properties: {}
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  name: '${environmentPrefix}-afd-endpoint-${uniqueSuffix}'
  parent: frontDoorProfile
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  name: 'appgw-origin-group'
  parent: frontDoorProfile
  dependsOn: [
    primaryAppGateway
    secondaryAppGateway
  ]
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

resource frontDoorPrimaryOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  name: 'primary-appgw-origin'
  parent: frontDoorOriginGroup
  properties: {
    hostName: primaryPublicIP.properties.dnsSettings.fqdn
    httpPort: 80
    httpsPort: 443
    originHostHeader: primaryPublicIP.properties.dnsSettings.fqdn
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource frontDoorSecondaryOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  name: 'secondary-appgw-origin'
  parent: frontDoorOriginGroup
  properties: {
    hostName: secondaryPublicIP.properties.dnsSettings.fqdn
    httpPort: 80
    httpsPort: 443
    originHostHeader: secondaryPublicIP.properties.dnsSettings.fqdn
    priority: 2
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  name: 'default-route'
  parent: frontDoorEndpoint
  dependsOn: [
    frontDoorOriginGroup
    frontDoorPrimaryOrigin
    frontDoorSecondaryOrigin
  ]
  properties: {
    originGroup: {
      id: frontDoorOriginGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
  }
}

// Parent Traffic Manager (Front Door + Regional TM)
resource parentTrafficManager 'Microsoft.Network/trafficmanagerprofiles@2022-04-01' = {
  name: '${environmentPrefix}-tm-parent-${uniqueSuffix}'
  location: 'global'
  dependsOn: [
    frontDoorEndpoint
    regionalTrafficManager
  ]
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Priority'
    dnsConfig: {
      relativeName: '${environmentPrefix}-tm-parent-${uniqueSuffix}'
      ttl: 30
    }
    monitorConfig: {
      protocol: 'HTTP'
      port: 80
      path: '/'
      intervalInSeconds: 30
      timeoutInSeconds: 10
      toleratedNumberOfFailures: 3
    }
    endpoints: [
      {
        name: 'frontdoor-endpoint'
        type: 'Microsoft.Network/trafficManagerProfiles/ExternalEndpoints'
        properties: {
          target: frontDoorEndpoint.properties.hostName
          endpointStatus: 'Enabled'
          priority: 1
        }
      }
      {
        name: 'regional-tm-endpoint'
        type: 'Microsoft.Network/trafficManagerProfiles/NestedEndpoints'
        properties: {
          targetResourceId: regionalTrafficManager.id
          endpointStatus: 'Enabled'
          priority: 2
          minChildEndpoints: 1
        }
      }
    ]
  }
}

// Outputs
output primaryAppServiceUrl string = 'https://${primaryAppService.properties.defaultHostName}'
output secondaryAppServiceUrl string = 'https://${secondaryAppService.properties.defaultHostName}'
output primaryAppGatewayFqdn string = primaryPublicIP.properties.dnsSettings.fqdn
output secondaryAppGatewayFqdn string = secondaryPublicIP.properties.dnsSettings.fqdn
output regionalTrafficManagerFqdn string = '${regionalTrafficManager.properties.dnsConfig.relativeName}.trafficmanager.net'
output frontDoorEndpointUrl string = 'https://${frontDoorEndpoint.properties.hostName}'
output parentTrafficManagerFqdn string = '${parentTrafficManager.properties.dnsConfig.relativeName}.trafficmanager.net'
