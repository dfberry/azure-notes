// main.bicep
targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''
param userManagedIdentity string = ''
param tenantId string = tenant().tenantId
param authTenantId string = ''

// Optional parameters to override the default azd resource naming conventions.
// Add the following to main.parameters.json to provide values:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param resourceGroupName string = ''

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tenantIdForAuth = !empty(authTenantId) ? authTenantId : tenantId
var authenticationIssuerUri = '${environment().authentication.loginEndpoint}${tenantId}/v2.0'

// Name of the service defined in azure.yaml
// A tag named azd-service-name with this value should be applied to the service host resource, such as:
//   Microsoft.Web/sites for appservice, function
// Example usage:
//   tags: union(tags, { 'azd-service-name': apiServiceName })
#disable-next-line no-unused-vars
var apiServiceName = 'python-api'
var keyVaultName = '${abbrs.keyVaultVaults}${resourceToken}'

param userManagedIdentityName string = '${environmentName}-user-managed-identity'

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module appSystemIdentity 'managedIdentity.bicep' = {
  name: 'managedIdentity'
  scope: rg
  params: {
    identityName: userManagedIdentityName
    location: location
  }
}

// Add resources to be provisioned below.
// A full example that leverages azd bicep modules can be seen in the todo-python-mongo template:
// https://github.com/Azure-Samples/todo-python-mongo/tree/main/infra

module keyVault 'core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: keyVaultName
    location: location
    principalId: appSystemIdentity.outputs.managedIdentity
  }
}

module keyVaultAccessManagedIdentity 'core/security/keyvault-access.bicep' = {
  name: 'keyvault-access-mi'
  scope: rg
  params: {
    keyVaultName: keyVaultName
    principalId: appSystemIdentity.outputs.managedIdentity
  }
}
module keyVaultAccessDeveloperIdentity 'core/security/keyvault-access.bicep' = {
  name: 'keyvault-access-developer'
  scope: rg
  params: {
    keyVaultName: keyVaultName
    principalId: principalId
  }
}

module secrets 'secrets.bicep' = {
  name: 'secrets'
  scope: rg
  params: {
    keyVaultName: keyVaultName
    name: 'hello'
    value: '1234'
  }
}

// Add outputs from the deployment here, if needed.
//
// This allows the outputs to be referenced by other bicep deployments in the deployment pipeline,
// or by the local machine as a way to reference created resources in Azure for local development.
// Secrets should not be added here.
//
// Outputs are automatically saved in the local azd environment .env file.
// To see these outputs, run `azd env get-values`,  or `azd env get-values --output json` for json output.
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenantId
output PRINCIPAL_ID string = principalId
output AUTHENTATION_ISSUER_URI string = authenticationIssuerUri
output USER_MANAGED_IDENTITY string = appSystemIdentity.outputs.managedIdentity
output RESOURCE_TOKEN string = resourceToken
output AZURE_AUTH_TENANT_ID string = tenantIdForAuth
