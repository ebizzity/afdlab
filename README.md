# Azure Front Door Failover Lab

This Bicep template deploys a comprehensive multi-layered failover architecture using Azure Front Door, Traffic Manager, Application Gateway, and App Services across multiple regions.

## Architecture Overview

The template creates a resilient multi-tier architecture with the following components:

```
Internet Traffic
       ↓
Parent Traffic Manager (Priority Routing)
    ↓               ↓
Front Door      Regional Traffic Manager
    ↓               ↓
App Gateways ← → App Gateways (Primary/Secondary)
    ↓               ↓
App Services    App Services (Regional)
```

### Components Deployed

- **2x App Services**: Regional web applications (Primary: Central US, Secondary: West US 2)
- **2x Application Gateways**: Load balancers with health probes for App Services
- **Regional Traffic Manager**: Routes traffic between Application Gateways based on health
- **Azure Front Door**: Global load balancer with caching and WAF capabilities
- **Parent Traffic Manager**: Top-level routing between Front Door and regional Traffic Manager
- **Virtual Networks**: Isolated network environments for each region
- **Public IP Addresses**: Static IPs for Application Gateways

## Deployment

### Prerequisites

- Azure CLI or Azure PowerShell
- Azure subscription with appropriate permissions
- Resource group (will be created if it doesn't exist)

### Quick Deploy

Click the button below to deploy directly to Azure:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Febizzity%2Fafdlab%2Fmain%2Fdeploy.json)

### Manual Deployment

#### Using Azure CLI

```bash
# Login to Azure
az login

# Create resource group
az group create --name afd-failover-lab --location "Central US"

# Deploy the template
az deployment group create \
  --resource-group afd-failover-lab \
  --template-file deploy.bicep \
  --parameters environmentPrefix="afd-lab" \
               primaryRegion="Central US" \
               secondaryRegion="West US 2" \
               appServicePlanSku="P1v3"
```

#### Using Azure PowerShell

```powershell
# Login to Azure
Connect-AzAccount

# Create resource group
New-AzResourceGroup -Name "afd-failover-lab" -Location "Central US"

# Deploy the template
New-AzResourceGroupDeployment `
  -ResourceGroupName "afd-failover-lab" `
  -TemplateFile "deploy.bicep" `
  -environmentPrefix "afd-lab" `
  -primaryRegion "Central US" `
  -secondaryRegion "West US 2" `
  -appServicePlanSku "P1v3"
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `primaryRegion` | string | Central US | Primary Azure region for deployment |
| `secondaryRegion` | string | West US 2 | Secondary Azure region for deployment |
| `environmentPrefix` | string | afd-lab | Prefix for resource naming |
| `appServicePlanSku` | string | P1v3 | SKU for App Service Plans |
| `applicationGatewaySku` | string | Standard_v2 | SKU for Application Gateways |

## Outputs

After deployment, the template provides the following outputs:

- `primaryAppServiceUrl`: URL of the primary App Service
- `secondaryAppServiceUrl`: URL of the secondary App Service  
- `primaryAppGatewayFqdn`: FQDN of the primary Application Gateway
- `secondaryAppGatewayFqdn`: FQDN of the secondary Application Gateway
- `regionalTrafficManagerFqdn`: FQDN of the regional Traffic Manager
- `frontDoorEndpointUrl`: URL of the Azure Front Door endpoint
- `parentTrafficManagerFqdn`: FQDN of the parent Traffic Manager (main entry point)

## Testing Failover

### Traffic Flow Testing

1. **Access the main endpoint**: Use the `parentTrafficManagerFqdn` output
2. **Test Front Door**: Use the `frontDoorEndpointUrl` output
3. **Test Regional TM**: Use the `regionalTrafficManagerFqdn` output

### Simulate Failures

1. **App Service Failure**: Stop one of the App Services to test Application Gateway failover
2. **Application Gateway Failure**: Stop one Application Gateway to test Traffic Manager failover
3. **Regional Failure**: Stop all resources in one region to test Front Door failover
4. **Front Door Failure**: Disable Front Door to test fallback to regional Traffic Manager

## Monitoring and Health Checks

### Health Probe Configuration

- **Application Gateway**: Monitors App Services on port 443 (HTTPS)
- **Traffic Manager**: Monitors Application Gateways on port 80 (HTTP)
- **Front Door**: Monitors Application Gateways with custom health probes
- **Parent Traffic Manager**: Monitors both Front Door and regional Traffic Manager

### Monitoring Endpoints

Access Azure Monitor to view:
- Application Gateway backend health
- Traffic Manager endpoint health
- Front Door origin health
- App Service availability metrics

## Architecture Benefits

### High Availability
- Multiple layers of redundancy
- Cross-region failover capability
- Health-based routing decisions

### Performance
- Global edge locations via Front Door
- Regional load balancing via Application Gateway
- Intelligent traffic routing

### Security
- HTTPS enforcement across all tiers
- Web Application Firewall capabilities
- Network isolation via VNets

## Cost Considerations

This template deploys multiple premium services. Consider the following for cost optimization:

- **App Service Plans**: P1v3 SKU includes auto-scaling capabilities
- **Application Gateway**: Standard_v2 includes WAF features
- **Front Door**: Standard tier provides core CDN and security features
- **Traffic Manager**: Pay-per-query pricing model

## Cleanup

To avoid ongoing charges, delete the resource group when the lab is complete:

```bash
az group delete --name afd-failover-lab --yes --no-wait
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- Create an issue in this repository
- Review Azure documentation for service-specific guidance
- Check Azure status page for service health

---

**Note**: This template is designed for learning and testing purposes. For production deployments, consider additional security hardening, monitoring, and backup strategies.