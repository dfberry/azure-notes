# azure-notes

## assign reviewer

```
#assign-reviewer: bob, Alex, mitchell, Karl
```

## Web properties

* [JavaScript at Microsoft](https://developer.microsoft.com/en-us/javascript/)
* [Learn (content)](https://learn.microsoft.com/)
* [Tech Communities](https://techcommunity.microsoft.com/)
* [Learn skills for jobs](https://opportunity.linkedin.com/skills-for-in-demand-jobs)
   * [Career Essentials in Software Development](https://www.linkedin.com/learning/paths/career-essentials-in-software-development)

## Azure

* [Azure resource explorer](https://resources.azure.com/)
* [Bicep Quickstart samples](https://github.com/Azure/azure-quickstart-templates)
 
* Easy auth:  
   * In resource explorer, location for easy auth is `/providers/Microsoft.Web/sites/APP-SERVICE-NAME/config/authsettingsV2/list?api-version=2020-12-01`
   * Login: https://APP-SERVICE-NAME.azurewebsites.net/.auth/login/aad
   * Logout: https://APP-SERVICE-NAME.azurewebsites.net/.auth/logout
   * loginParameters for easy auth single app only: ["response_type=code id_token","scope=openid offline_access profile"]
   * loginParameters for easy auth single app only + Graph: ["response_type=code id_token","scope=openid offline_access profile https://graph.microsoft.com/User.Read"]
   * loginParameters for easy auth single app only + Graph + 2nd app's API: ["response_type=code id_token","scope=openid offline_access profile https://graph.microsoft.com/User.Read api://SECOND-APP-CLIENT-ID/user_impersonation"]

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

### Access token

Obtain an access token from MSI and then use it as a bearer token:

```shell
az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken --output tsv

ab1234512345... <-- your token
```


### Azure endpoints

REST-based endpoints are available on the Overview page of each resource. When using with environment variables, use the entire URL instead of a string manipulation with the resource name because federal clouds have different domains or subdomains where a single resource name substitution is not enough. 
  
## Azure CLI

### Current regions with programmatic names

```
az account list-locations -o table
```

### Current logged-in user

```
# acquire logged in user context
export CURRENT_USER=$(az account show --query user.name -o tsv)
export CURRENT_USER_OBJECTID=$(az ad user show --id $CURRENT_USER --query objectId -o tst)
```

### sorted results

Example of sorting all subscriptions by name. Supporting [documentation](https://learn.microsoft.com/cli/azure/query-azure-cli?tabs=concepts%2Cbash#manipulating-output-with-functions) for `sort_by`.

```
az account list --query "sort_by([].{Name:name, SubscriptionId:id, TenantId:tenantId}, &Name)" --output table
```

## Azure Developer CLI

```
azd auth login --tenant-id <YOUR_TENANT_ID>
```

## Azure OpenAI

* `apiVersion`: this refers to the REST version, not the deployment's model version.

### Rag chat overrides

<img width="821" alt="image" src="https://github.com/dfberry/azure-notes/assets/1517008/2e822d4d-c71d-4287-89ce-aeb166784cdc">

### Samples

Make sure to look at the Functions samples too.

* [Fastify](https://github.com/Azure-Samples/azure-openai-rag-workshop/blob/base/src/backend-node-qdrant/src/plugins/chat.ts)
* [AI Studio CoPilot sample](https://github.com/Azure/aistudio-copilot-sample)
* [Contoso Chat](https://github.com/Azure-Samples/contoso-chat): This sample has the full End2End process of creating RAG application with Prompt Flow and AI Studio. It includes GPT 3.5 Turbo LLM application code, evaluations, deployment automation with AZD CLI, GitHub actions for evaluation and deployment and intent mapping for multiple LLM task mapping.
* [AI-in-a-Box](https://github.com/Azure/AI-in-a-Box)
  
## Azurite

### Azurite + SDK

Conceptual steps

1.	Create a self-signed certificate and get it into your local certificate store
1.	Start Azurite with that certificate. 
1.	Start client app with ability for HTTP client inside SDK to ignore SSL/TLS rejections.
1.	Client calls SDK
1.	Success!

#### Create and trust self-signed certificate

1. Create self-signed certificate

  ```bash
  openssl req -newkey rsa:2048 -x509 -nodes -keyout key.pem -new -out cert.pem -sha256 -days 365 -addext 'subjectAltName=IP:127.0.0.1' -subj '/C=CO/ST=ST/L=LO/O=OR/OU=OU/CN=CN'"
  ```
  
1. Trust certificate by adding it to local certificate store

  ```bash
  sudo update-ca-certificates 
  ```
  
1. Verify certificate in store

  ```bash
  sudo openssl x509 -in /etc/ssl/certs/ca-certificates.crt -text -noout | grep "Subject:"
  ```

#### Start Azurite with that certificate

```bash
azurite --location azurite --debug azurite/debug.log --oauth basic --cert ./cert.pem --key ./key.pem
```

SDK needs `--oauth basic`.

#### Start client app to ignore SSL/TLS rejections

For Node.js Azure SDKS, set the following environment variable:

```ini
NODE_TLS_REJECT_UNAUTHORIZED=false
NODE_TLS_REJECT_UNAUTHORIZED='0'
```

For Azure Storage SDK:

```typescript
import {
  BlobServiceClient
} from "@azure/storage-blob";

export const createContainer = async (
  connectionString: string,
  containerName: string)=> {
  // get storage client
  const blobServiceClient = BlobServiceClient.fromConnectionString(
    connectionString
  );

  // get container client
  const containerClient = blobServiceClient.getContainerClient(
    containerName
  );
  const createContainerResult = containerClient.createIfNotExists();
  return createContainerResult;
}

async function main(){

    const container = `test-${Date.now()}`;
    console.log(container);

    process.env["NODE_TLS_REJECT_UNAUTHORIZED"]='0';
    const connectionString = process.env["STORAGE_CONNECTIONSTRING"] as string;
    const sasInfo = await createContainer(
        connectionString,
        container);
    
    console.log(sasInfo.errorCode)

    return sasInfo.errorCode;
}

main().then((results)=>{
    console.log(JSON.stringify(results))
}).catch(err=>console.log(err))
```

## Azure SDK

* Iterators and paging through results
  * Brian's blob post: [Async Iterators in the Azure SDK for JavaScript/TypeScript](https://devblogs.microsoft.com/azure-sdk/async-iterators-in-the-azure-sdk-for-javascript-typescript/)
  * In order to get continuation token for next page, you have to call .next()

## Azure Container Apps

### Stop container app

* [Issue](https://github.com/microsoft/azure-container-apps/issues/901#issuecomment-1714706153)

```bash
ID=$(az containerapp show -n {} -g {} -o tsv --query id)

# Stop
az rest \
  --method post \
  --url "${ID}/stop?api-version=2023-05-01"

# Start
az rest \
  --method post \
  --url "${ID}/start?api-version=2023-05-01"
```

## Active Directory

* 2023 - renamed to Entra ID

### App registrations

* Error:  "The directory object quota limit for the Principal has been exceeded. Please ask your administrator to increase the quota limit or delete objects to reduce the used quota." - [StackOverflow showing PowerShell command to fix](https://stackoverflow.com/questions/58935129/cant-create-new-service-principals-in-azure-despite-being-under-quota)

### Passwordless connections

* [Passwordless connections for Azure services](https://learn.microsoft.com/en-us/azure/developer/intro/passwordless-overview)

### Roles

#### Find role id by role

While you can use the az command `az role definition list`, it might be easier to create the Azure service then look at the possiblities in the IAM section for roles.

#### Find role by role id

```bash
az role definition list
```

Output looks like: 

```console
[
{
    "assignableScopes": [
      "/"
    ],
    "createdBy": null,
    "createdOn": "2023-12-15T06:02:00.574768+00:00",
    "description": "Read, write, and delete KubernetesRuntime storage classes in an Arc connected Kubernetes cluster",
    "id": "/subscriptions/52942f45-54fd-4fd9-b730-03d518fedf35/providers/Microsoft.Authorization/roleDefinitions/0cd9749a-3aaf-4ae5-8803-bd217705bf3b",
    "name": "0cd9749a-3aaf-4ae5-8803-bd217705bf3b",
    "permissions": [
      {
        "actions": [
          "Microsoft.KubernetesRuntime/storageClasses/read",
          "Microsoft.KubernetesRuntime/storageClasses/write",
          "Microsoft.KubernetesRuntime/storageClasses/delete",
          "Microsoft.Authorization/*/read",
          "Microsoft.Insights/alertRules/*",
          "Microsoft.Resources/deployments/*",
          "Microsoft.Resources/subscriptions/resourceGroups/read"
        ],
        "condition": null,
        "conditionVersion": null,
        "dataActions": [],
        "notActions": [],
        "notDataActions": []
      }
    ],
    "roleName": "KubernetesRuntime Storage Class Contributor Role",
    "roleType": "BuiltInRole",
    "type": "Microsoft.Authorization/roleDefinitions",
    "updatedBy": null,
    "updatedOn": "2023-12-15T06:02:00.574768+00:00"
  }
]
```

## Azure App Service

* Easy auth settings
  * WEBSITE_AUTH_CLIENT - don't create - is created and hidden when you configure easy auth
  * MICROSOFT_PROVIDER_AUTHENTICATION_SECRET - set this to the app registration secret
  * WEBSITE_AUTH_TENANT_ID - this is either your tenant or "COMMON", might be another name depending on how the config is programmed in JS
* Port
  * 8080 is default
 * change via App Setting ->  WEBSITES_PORT or use following
      ```
      process.env.PORT || 3000
      ```
* Install NPM packages after Zip deploy
  * App Setting -> SCM_DO_BUILD_DURING_DEPLOYMENT -> true - this setting is created for you if you create app service from VSCode
* Configure logging to container logs
  * Monitoring -> Logs -> Enable
  * Download lixux logs: https://YOUR-RESOURCE-NAME.scm.azurewebsites.net/api/logs/docker/zip
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

## Azure Cloud shell

[Azure cloud shell](https://ms.portal.azure.com/#cloudshell/) allows you to use Azure CLI without having to install it. 

* Has [jq](https://stedolan.github.io/jq/) (commandline JSON processor) installed

## Azure Functions

### Monorepos

Monorepos aren't supported in some of the Visual Studio Code and GitHub tooling, especially if managed Functions + SWA. Be careful how you set it up.

### CICD

To enable remote build on Linux, you must set these application settings:

* ENABLE_ORYX_BUILD=true
* SCM_DO_BUILD_DURING_DEPLOYMENT=true

Make sure to checkin package-lock.json for deploy to Azure

### AI 

* [OpenAI binding Source repo](https://github.com/Azure/azure-functions-openai-extension)
* [LangChainjs](https://github.com/Azure-Samples/serverless-chat-langchainjs)

### Sample code 

* [Azure/azure-functions-nodejs-samples](https://github.com/Azure/azure-functions-nodejs-samples)
* [Azure-Samples/functions-docs-javascript](https://github.com/Azure-Samples/functions-docs-javascript)
* [ejizba/azure-functions-nodejs-stream](https://github.com/ejizba/azure-functions-nodejs-stream)
* [ejizba/azure-functions-nodejs-samples](https://github.com/ejizba/azure-functions-nodejs-samples)
* [ejizba/azure-functions-ts-binding-samples](https://github.com/ejizba/azure-functions-ts-binding-samples)
* [ejizba/azure-functions-js-binding-samples](https://github.com/ejizba/azure-functions-js-binding-samples)
* [ejizba/allTheTriggersV3](https://github.com/ejizba/allTheTriggersV3)




## Azure SDK

* Iterators and paging through results
  * Brian's blob post: [Async Iterators in the Azure SDK for JavaScript/TypeScript](https://devblogs.microsoft.com/azure-sdk/async-iterators-in-the-azure-sdk-for-javascript-typescript/)
  * In order to get continuation token for next page, you have to call .next()

## Cognitive Services

* [samples repo](https://github.com/Azure-Samples/cognitive-services-quickstart-code)

### Content moderator

* [Sample image](https://moderatorsampleimages.blob.core.windows.net/samples/sample2.jpg)

## Databases

* [AdventureWorks](https://docs.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver16&tabs=ssms)
* [Convert SQL API JSON to MongoDB API BSON](https://gist.github.com/seesharprun/c36fcc13c1c5766a4ae38439729dbe65) - .NET gist
   * [Cosmisworks data](https://github.com/seesharprun/cosmicworkstool/tree/main/src/node/data) - customers and products 
   * [Customers.json](https://gist.github.com/seesharprun/c36fcc13c1c5766a4ae38439729dbe65#file-customers-json)
   * [Products.json](https://gist.github.com/seesharprun/c36fcc13c1c5766a4ae38439729dbe65#file-products-json)
* Azure SDK for Cosmos DB
   * [Families.json](https://github.com/Azure/azure-sdk-for-js/blob/main/sdk/cosmosdb/cosmos/samples/v3/javascript/Data/Families.json)
* [CosmicWorks](https://github.com/azurecosmosdb/cosmicworks) - GitHub repo
* [cosmos-db-mongodb-api-javascript-samples](https://github.com/Azure-Samples/cosmos-db-mongodb-api-javascript-samples) - GitHub repo 
* [MongoDB aggregations book](https://www.practical-mongodb-aggregations.com/)
* [Cognitive Search 10K books](https://github.com/Azure-Samples/azure-search-javascript-samples/blob/main/search-website/bulk-insert/good-books-index.json)

### Cosmos DB

* Server-side JS - [Azure/azure-cosmosdb-js-server](https://github.com/Azure/azure-cosmosdb-js-server)
* [Node sp sample](https://github.com/Azure/azure-cosmosdb-node/tree/master/samples/ServerSideScripts)

#### Test Cosmos DB connection

Retries indefinitely so give it an amount of time a read should succeed in, then hard fail if that time is exceeded. 

```typescript
import { CosmosClient } from '@azure/cosmos';
import { v4 as uuidv4 } from 'uuid';
import * as dotenv from 'dotenv';
dotenv.config();

function withTimeout<T>(promise: Promise<T>, timeoutMs: number): Promise<T> {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      reject(new Error('Timeout exceeded'));
    }, timeoutMs);

    promise
      .then((result) => {
        clearTimeout(timeout);
        resolve(result);
      })
      .catch((error) => {
        clearTimeout(timeout);
        reject(error);
    });
  });
}

async function insertData(
  resourceName: string,
  key: string,
  data: any,
  databaseName = 'test',
  containerName = 'test'
): Promise<any> {
  const client = new CosmosClient({
    endpoint: `https://${resourceName}.documents.azure.com`,
    key
  });
  console.log('client created');
  const { database } = await client.databases.createIfNotExists({
    id: databaseName
  });
  console.log('database created');
  const { container } = await database.containers.createIfNotExists({
    id: containerName
  });
  console.log('container created');
  const { resource: item } = await container.items.create({
    id: uuidv4().toString(),
    ...data
  });
  console.log('item created');
  return item;
}


const name = process.env.AZURE_COSMOSDB_NAME as string;
const key = process.env.AZURE_COSMOSDB_KEY as string;
const timeoutMs = 10000;
const wrappedPromise = withTimeout(
  insertData(name, key, { name: 'hello', age: 21 }),
  timeoutMs
);

wrappedPromise
  .then((result) => {
  console.log('Operation finished ', result); // Data fetched successfully
  process.exit(0);
  })
  .catch((error) => {
  console.log('Operation didn\'t finish', error.message); // Timeout exceeded
  process.exit(1);
  });
```

### PostgreSQL

#### Prisma URL

```
postgresql://USER@RESOURCENAME:PASSWORD@RESOURCENAME.postgres.database.azure.com:5432/DATABASENAME?&sslmode=require
```

## Database emulators

* [Cosmos DB from container for linux](https://docs.microsoft.com/en-us/azure/cosmos-db/linux-emulator?tabs=sql-api%2Cssl-netstd21#run-the-linux-emulator-on-macos)

## Debug SAS tokens

* Create SAS token in portal then compare to SAS token created with generateBlobSASQueryParameters

## Deployment logs

Deployment logs are available from the subscription under **Settings => Deployments**. Find the deployment and select **Delete**.

## Functions

### host.json

* Timer trigger won't run if you are logging to Application Insights with too high a sampling rate
* Timer trigger may stop working if functions run past default timeout (set the default timeout explicitly)
* Review "Diagnose and solve problems" in portal to find issues

### Custom `route` in `function.json`

```json
{
    "bindings": [
    {
        "type": "httpTrigger",
        "name": "req",
        "direction": "in",
        "methods": [ "get" ],
        "route": "products/{category:alpha}/{id:int?}"
    },
    {
        "type": "http",
        "name": "res",
        "direction": "out"
    }
    ]
}
```

### Blob trigger settings in host.json

Notice that blob trigger follows the queue trigger settings.

```
{
    "version": "2.0",
    "extensions": {
        "queues": {
            "maxPollingInterval": "00:00:02",
            "visibilityTimeout" : "00:00:30",
            "batchSize": 16,
            "maxDequeueCount": 5,               // retries the function for that blob 5 times by default
            "newBatchThreshold": 8,
            "messageEncoding": "base64"
        }
    }
}

```

### Azure Functions - GitHub action

* [Azure Functions Action](https://github.com/marketplace/actions/azure-functions-action)

```
- name: 'Run Azure Functions Action'
  uses: Azure/functions-action@v1
  id: fa
  with:
    app-name: 'AdvocacyGithubTraffic'
    slot-name: 'Production'
    package: '${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}/output'
    publish-profile: ${{ secrets.AZUREAPPSERVICE_PUBLISHPROFILE_6F0DB2747FBF4EFFADD6A4472638F303 }}
```

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

The Learn sandbox subscription has the following name and tenant ID:

* Name: Concierge Subscription
* Tenant ID: 604c1504-c6a3-4080-81aa-b33091104187

## Microsoft Graph

### My profile from SDK

```javascript
// package.json - type: "module"

import graph from '@microsoft/microsoft-graph-client';
import 'isomorphic-fetch';

const getAuthenticatedClient = (accessToken) => {
    // Initialize Graph client
    const client = graph.Client.init({
        // Use the provided access token to authenticate requests
        authProvider: (done) => {
            done(null, accessToken);
        }
    });

    return client;
}

// https://developer.microsoft.com/en-us/graph/graph-explorer
// https://jwt.ms/
// https://github.com/Azure-Samples/ms-identity-easyauth-nodejs-storage-graphapi/blob/main/2-WebApp-graphapi-on-behalf/controllers/graphController.js

const main = async (accessToken) => {


    try {
        const graphClient = getAuthenticatedClient(accessToken);

        const profile = await graphClient
        .api('/me')
        .get();

        return profile;

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

## Passwordless connections to Azure Services

* [Passwordless connections for Azure services](https://learn.microsoft.com/en-us/azure/developer/intro/passwordless-overview)
* Prefer user-assigned over system-assigned

## Playwright

* Run as root, browsers are installed per user
* Playwright uses the native/container IP/network so use the internal container's port for api and web when testing with Playwright - verified on local dev container, haven't verified with Codespaces

## PowerShell

* Run from VSCode integrated terminal to avoid having to run in admin-elevated-privileges terminal. 
* Use `-Scope CurrentUser` so you don't have to use elevated priveledges

    ```azurepowershell-interactive
    Install-Module -Name Az.Search -Scope CurrentUser
    ```


## Static web app CLI

### Start proxy for running front and backend

```
swa start http://localhost:4200 --api-devserver-url http://localhost:7071
```

## Visual Studio Code

## Docker containers for dev containers

* [GitHub templates of containers](https://github.com/microsoft/vscode-dev-containers)

### Log issue against an Azure extension

1. Look up extension in [marketplace](https://marketplace.visualstudio.com/items)
2. On extensions page on marketplace, find source code repo under project details
3. Open issue on repo

### Debug with current file

In `./.vscode/launch.json` file:

```
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "type": "node",
            "request": "launch",
            "name": "Launch Program",
            "skipFiles": [
                "<node_internals>/**"
            ],
            // Use the ${file} variables
            "program": "${workspaceFolder}\\${file}"
        }
    ]
}
```

### Debug with external terminal

In `./.vscode/launch.json` file:

```
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "type": "node",
            "request": "launch",
            "name": "Launch Program",
            "skipFiles": [
                "<node_internals>/**"
            ],
            "program": "${workspaceFolder}\\${file}",
            // Use this line to indicate an external terminal - such as reading into program from user input
            "console": "externalTerminal"
        }
    ]
}
```

### Debugging Azure Functions

#### Error: Can't find task for func: host start

* [StackOverflow of ideas to try](https://stackoverflow.com/questions/56881688/could-not-find-the-task-func-host-start)
* Always run functions app in docker container because Functions runtime are directly tied to Node runtime
* Make sure Azure Functions extensions in installed and _loaded_ in VS Code in the container. The extenion may be in ./vscode/extensions.json, but may not be loaded correctly
