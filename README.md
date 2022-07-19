# azure-notes

## Azure

* [Azure resource explorer](https://resources.azure.com/)
    * Easy auth:  /providers/Microsoft.Web/sites/APP-SERVICE-NAME/config/authsettingsV2/list?api-version=2020-12-01

        ```
        "identityProviders": {
              "azureActiveDirectory": {
                "enabled": true,
                "registration": {
                  "openIdIssuer": "https://sts.windows.net/51397421-87d6-42c1-8bab-98305329d75c/v2.0",
                  "clientId": "4480f5c3-01a7-426a-b602-dba4e7b3f776",
                  "clientSecretSettingName": "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"
                },
                "login": {
                  "loginParameters": [
                    "response_type=code id_token",
                    "scope=openid offline_access profile https://graph.microsoft.com/User.Read"
                  ],
                  "disableWWWAuthenticate": false
                },
                "validation": {
                  "jwtClaimChecks": {},
                  "allowedAudiences": [],
                  "defaultAuthorizationPolicy": {
                    "allowedPrincipals": {}
                  }
                }
              }}        
        ```

## Azure App Service

* Easy auth settings
  * WEBSITE_AUTH_CLIENT - don't create - is created and hidden when you configure easy auth
  * MICROSOFT_PROVIDER_AUTHENTICATION_SECRET - set this to the app registration secret
  * WEBSITE_AUTH_TENANT_ID - this is either your tenant or "COMMON", might be another name depending on how the config is programmed in JS
* Port
  * 8080 is default
  * change via App Setting ->  WEBSITES_PORT
* Install NPM packages after Zip deploy
  * App Setting -> SCM_DO_BUILD_DURING_DEPLOYMENT -> true
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
* View logs
    * container startup logs: /Logs/*_docker.log
    * runtime logs (console.log: /Logs/*_default_docker.log
    * easyauth: /Logs/*_easyauth_docker.log

## Debug SAS tokens

* Create SAS token in portal then compare to SAS token created with generateBlobSASQueryParameters

## GitHub

### Actions

#### Ignore node_modules in artifact

```yaml
- name: Upload artifact for deployment job
  uses: actions/upload-artifact@v2
  with:
    name: ${{ secrets.DEPLOY_APP_NAME }}
    path: |
         .
         !./node_modules
```

* Found in [basic-express-typescript](https://github.com/dfberry/basic-express-typescript/blob/main/.github/workflows/deploy-to-stage.yml)
* Combine with App Service deployment
    * Install NPM packages after Zip deploy
    * App Setting -> SCM_DO_BUILD_DURING_DEPLOYMENT -> true 
## Learn sandbox

If learn sandbox doesn't let you in, recreate a new one which resets. 
* Must switch tenant to Sandbox tenant in both portal and VSCode

## Microsoft Graph

### My profile from REST

```javascript
// package.json - type: "module"

import axios from 'axios';


// https://developer.microsoft.com/en-us/graph/graph-explorer
// https://jwt.ms/

const main = async (accessToken) => {


    try {

        const url = 'https://graph.microsoft.com/v1.0/me';

        const options = {
            method: 'GET',
            headers: {
                Authorization: 'Bearer ' + accessToken,
                'Content-type': 'application/json',
            },
        };

        const graphResponse = await axios.get(url, options);

        const { data } = await graphResponse;
        return data;

    } catch (err) {
        throw err;
    }
}

const accessToken = "... replace with your access token ...";

main(accessToken).then((userData)=>{
    console.log(userData);
}).catch((err)=>{
    console.log(err);
})

```
