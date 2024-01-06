param location string = resourceGroup().location

@description('The name of the identity')
param identityName string

resource managedUserIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

output managedIdentity string = managedUserIdentity.properties.principalId

