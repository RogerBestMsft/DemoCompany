# Read structure from structure.yml
$structure = Get-Content -Path .\structure.json | ConvertFrom-Json -Depth 20

# Create the devcenter
$devCenterRG = az deployment sub create `
    --subscription $structure.subscriptionId.ToString() `
    --location $structure.location.ToString() `
    --template-file .\resourceGroup.bicep `
    --parameters name="$($structure.resourceGroupName.ToString())" location="$($structure.location.ToString())" 

$devCenter = az deployment group create `
    --subscription $structure.subscriptionId.ToString() `
    --resource-group $structure.resourceGroupName.ToString() `
    --template-file .\devcenter.bicep `
    --parameters name="$($structure.name.ToString())" `
        location="$($structure.location.ToString())" `
        keyVaultName="$($structure.keyVaultName.ToString())" `
        galleryName="$($structure.galleryName.ToString())" `
        repoUri="$($structure.repoUri.ToString())" `
        repoAccess="$($structure.repoAccess.ToString())" `
        repoPath="$($structure.repoPath.ToString())" 
        #vnet=$vnetB `
        #environmentTypes=$envA


foreach ($project in $structure.projects) {

    $projectRG = az deployment sub create `
        --subscription $project.subscriptionId.ToString() `
        --location $project.location.ToString() `
        --template-file .\resourceGroup.bicep `
        --parameters name="$($project.Name.ToString())" location="$($project.location.ToString())"

    
    $project = az deployment sub create `
        --subscription $project.subscriptionId.ToString() `
        --location $project.location.ToString() `
        --template-file .\projectsetup.bicep `
        --debug `
        --parameters name="$($project.name.ToString())" `
            subscriptionId="$($project.subscriptionId.ToString())" `
            location="$($project.location.ToString())" `
            name="$($project.name.ToString())" `
            resourceGroupName="$($project.name.ToString())" `
            devCenterSubId="$($structure.subscriptionId.ToString())" `
            devCenterRGName="$($structure.resourceGroupName.ToString())" `
            devCenterName="$($structure.name.ToString())"
            #projectAdmins="$($project.projectAdmins.ToString())" `
            #devBoxUsers="$($project.devBoxUsers.ToString())" `
            #environmentUsers="$($project.environmentUsers.ToString())" `
            #environmentTypes="$($structure.environmentTypes.ToString())" 

        #param location string = resourceGroup().location
        #param description string = ''
        #--subscription $project.subscriptionId.ToString() `
        #--resource-group $project.name.ToString() `

#param ciPrincipalId string
#param tags object = {}
#param environmentTypes object = {}
        
}

#$outputsp = az ad sp create-for-rbac
#az deployment sub create --location eastus --template-file main.bicep --parameters '{ "ciPrincipalId": {"value":"$($outputsp.appId)"}}'


