$outputsp = az ad sp create-for-rbac

az deployment sub create --location eastus --template-file main.bicep --parameters '{ "ciPrincipalId": {"value":"$($outputsp.appId)"}}'