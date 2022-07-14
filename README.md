# azure-notes

## Azure

* [Azure resource explorer](https://resources.azure.com/)

## Azure App Service

* Configure logging to container logs
  * Monitoring -> Logs -> Enable
* Configure application insights
  * Settings -> Configuration -> Turn on Application Insights   
* Configure easy auth:
  * Add Authentication with Microsoft Identity provider, copy client id to notepad (id and secret are already in app settings for you)
  * Configure `authsettingsV2` in Azure Resource Explorer (link above) to add the `login` section
      ```
      "identityProviders": {
          "azureActiveDirectory": {
            "enabled": true,
            "login": {
              "loginParameters":[
                "response_type=code id_token",
                "scope=openid offline_access profile https://graph.microsoft.com/User.Read"
              ]
            }
          }
        }
      },
      ```

## Learn sandbox

If learn sandbox doesn't let you in, recreate a new one which resets. 
