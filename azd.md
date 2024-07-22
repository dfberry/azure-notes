---
---
#Azure Developer CLI

## Scripts to add for provisioning and deployment

### Add local IP to Azure firewall

* [Example in Contoso Real Estate](https://github.com/Azure-Samples/contoso-real-estate/pull/338/files#diff-5b7312807a73add65a2e551ce55d8754822f4b58296940b72587973b8dd88ccb)

  ```
  # Skip for local development
  if [ ! -f /.dockerenv ]; then
    # Add current public IP to firewall exceptions 
    my_public_ip="$(curl -s https://api.ipify.org)"
  
    echo "Adding current public IP to firewall exceptions..."
    az postgres flexible-server firewall-rule create \
      --resource-group "rg-$AZURE_ENV_NAME" \
      --name "$CMS_DATABASE_SERVER_NAME" \
      --rule-name "AllowMyIP" \
      --start-ip-address "$my_public_ip" \
      --end-ip-address "$my_public_ip" \
      --output none
  fi
  ```
