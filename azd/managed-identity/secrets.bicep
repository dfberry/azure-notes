//
param keyVaultName string
param name string
param value string

module computerVisionKVSecret 'core/security/keyvault-secret.bicep' =  {
  name: 'keyvault-secret'
  params: {
    keyVaultName: keyVaultName 
    name: name
    secretValue: value
  }
}
