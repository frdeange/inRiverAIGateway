param(
    [string]$SubscriptionId,
    [string]$ResourceGroupName = "rg-aigateway-demo",
    [string]$PrimaryRegion = "swedencentral",
    [string[]]$FoundryRegions = @("swedencentral", "francecentral", "northeurope"),
    [string]$NamePrefix = "aigwdemo",
    [string]$Gpt4oDeploymentName = "gpt-4o",
    [string]$Gpt4oModelVersion = "2024-11-20",
    [switch]$IncludeFunctions,
    [switch]$SkipModelDeployment
)

$ErrorActionPreference = "Stop"

function Get-RandomSuffix {
    return -join ((97..122) + (48..57) | Get-Random -Count 6 | ForEach-Object {[char]$_})
}

function Ensure-AzLogin {
    try {
        az account show --only-show-errors | Out-Null
    }
    catch {
        throw "Azure CLI is not logged in. Run 'az login' first."
    }
}

function Set-SubscriptionIfProvided {
    param([string]$SubId)
    if (-not [string]::IsNullOrWhiteSpace($SubId)) {
        az account set --subscription $SubId --only-show-errors
    }
}

function Get-FoundryAccountKey {
    param(
        [string]$AccountName,
        [string]$ResourceGroup
    )

    try {
        $key = az cognitiveservices account keys list `
            --name $AccountName `
            --resource-group $ResourceGroup `
            --query key1 `
            --only-show-errors `
            -o tsv 2>$null

        if (-not [string]::IsNullOrWhiteSpace($key)) {
            return $key
        }
    }
    catch {
    }

    return "<entra-id-only-local-auth-disabled>"
}

function Deploy-FoundryRegion {
    param(
        [string]$Region,
        [string]$TemplateFile,
        [string]$BaseName,
        [string]$ResourceGroup
    )

    Write-Host "Deploying AI Foundry resources in $Region using $TemplateFile"
    az deployment group create `
        --resource-group $ResourceGroup `
        --template-file $TemplateFile `
        --parameters "baseName=$BaseName" `
        --only-show-errors | Out-Null

    $accountName = "$BaseName-ais"
    $projectName = "$BaseName-project"

    $accountId = az cognitiveservices account show `
        --name $accountName `
        --resource-group $ResourceGroup `
        --query id `
        --only-show-errors `
        -o tsv

    $endpoint = az cognitiveservices account show `
        --name $accountName `
        --resource-group $ResourceGroup `
        --query properties.endpoint `
        --only-show-errors `
        -o tsv

    $projectId = az resource show `
        --resource-group $ResourceGroup `
        --resource-type "Microsoft.CognitiveServices/accounts/projects" `
        --name "$accountName/$projectName" `
        --api-version "2025-10-01-preview" `
        --query id `
        --only-show-errors `
        -o tsv

    $projectKey = Get-FoundryAccountKey -AccountName $accountName -ResourceGroup $ResourceGroup

    return [PSCustomObject]@{
        Region = $Region
        AccountName = $accountName
        AccountId = $accountId
        ProjectName = $projectName
        ProjectId = $projectId
        ProjectEndpoint = $endpoint.TrimEnd("/")
        ProjectKey = $projectKey
        DeploymentName = $Gpt4oDeploymentName
        DeploymentStatus = "DeployedViaARM"
        DeploymentDetail = "Microsoft.CognitiveServices/accounts + projects + deployments deployed via ARM template."
    }
}

Ensure-AzLogin
Set-SubscriptionIfProvided -SubId $SubscriptionId

Write-Host "Creating resource group '$ResourceGroupName' in $PrimaryRegion"
az group create --name $ResourceGroupName --location $PrimaryRegion --only-show-errors | Out-Null

$lawName = (($NamePrefix + "law" + (Get-RandomSuffix))).ToLower()
if ($lawName.Length -gt 63) { $lawName = $lawName.Substring(0, 63) }
Write-Host "Creating Log Analytics workspace: $lawName"
az monitor log-analytics workspace create --resource-group $ResourceGroupName --workspace-name $lawName --location $PrimaryRegion --only-show-errors | Out-Null
$lawResourceId = az monitor log-analytics workspace show --resource-group $ResourceGroupName --workspace-name $lawName --query id -o tsv
$lawCustomerId = az monitor log-analytics workspace show --resource-group $ResourceGroupName --workspace-name $lawName --query customerId -o tsv

$appInsightsName = (($NamePrefix + "appi" + (Get-RandomSuffix))).ToLower()
if ($appInsightsName.Length -gt 64) { $appInsightsName = $appInsightsName.Substring(0, 64) }
Write-Host "Creating Application Insights: $appInsightsName"
az monitor app-insights component create `
    --app $appInsightsName `
    --location $PrimaryRegion `
    --resource-group $ResourceGroupName `
    --workspace $lawResourceId `
    --kind web `
    --application-type web `
    --only-show-errors | Out-Null
$appInsightsConnectionString = az monitor app-insights component show --app $appInsightsName --resource-group $ResourceGroupName --query connectionString -o tsv

$foundryProjects = @()
$foundryProjects += Deploy-FoundryRegion -Region "swedencentral" -TemplateFile (Join-Path $PSScriptRoot "arm-templates\foundry-swedencentral.json") -BaseName "aigateway-demo-sec" -ResourceGroup $ResourceGroupName
$foundryProjects += Deploy-FoundryRegion -Region "francecentral" -TemplateFile (Join-Path $PSScriptRoot "arm-templates\foundry-francecentral.json") -BaseName "aigateway-demo-frc" -ResourceGroup $ResourceGroupName
$foundryProjects += Deploy-FoundryRegion -Region "northeurope" -TemplateFile (Join-Path $PSScriptRoot "arm-templates\foundry-northeurope.json") -BaseName "aigateway-demo-neu" -ResourceGroup $ResourceGroupName

$primaryFoundry = $foundryProjects | Where-Object { $_.Region -eq "swedencentral" } | Select-Object -First 1

$functionAppName = ""
$functionBaseUrl = ""
if ($IncludeFunctions.IsPresent) {
    $storageName = (($NamePrefix + "st" + (Get-RandomSuffix))).ToLower()
    if ($storageName.Length -gt 24) { $storageName = $storageName.Substring(0, 24) }

    $functionAppName = (($NamePrefix + "func" + (Get-RandomSuffix))).ToLower()
    if ($functionAppName.Length -gt 60) { $functionAppName = $functionAppName.Substring(0, 60) }

    Write-Host "Creating Function storage account: $storageName"
    az storage account create `
        --name $storageName `
        --resource-group $ResourceGroupName `
        --location $PrimaryRegion `
        --sku Standard_LRS `
        --kind StorageV2 `
        --only-show-errors | Out-Null

    Write-Host "Creating Function App (Consumption): $functionAppName"
    az functionapp create `
        --name $functionAppName `
        --resource-group $ResourceGroupName `
        --consumption-plan-location $PrimaryRegion `
        --storage-account $storageName `
        --functions-version 4 `
        --runtime python `
        --runtime-version 3.11 `
        --os-type Linux `
        --only-show-errors | Out-Null

    $functionBaseUrl = "https://$functionAppName.azurewebsites.net/api"
}

$envPath = Join-Path $PSScriptRoot ".env"
$subscriptionId = az account show --query id -o tsv
$tenantId = az account show --query tenantId -o tsv

$envLines = @(
    "# Generated at 2026-05-11T01:53:54.450+02:00",
    "AZURE_SUBSCRIPTION_ID=$subscriptionId",
    "AZURE_TENANT_ID=$tenantId",
    "RESOURCE_GROUP_NAME=$ResourceGroupName",
    "PRIMARY_REGION=$PrimaryRegion",
    "LOG_ANALYTICS_WORKSPACE_NAME=$lawName",
    "LOG_ANALYTICS_WORKSPACE_ID=$lawCustomerId",
    "APPINSIGHTS_NAME=$appInsightsName",
    "APPLICATIONINSIGHTS_CONNECTION_STRING=$appInsightsConnectionString",
    "FOUNDRY_PRIMARY_HUB_NAME=$($primaryFoundry.AccountName)",
    "FOUNDRY_PRIMARY_HUB_ID=$($primaryFoundry.AccountId)",
    "FOUNDRY_DEFAULT_DEPLOYMENT=$Gpt4oDeploymentName",
    "APIM_NAME=<set-after-manual-create>",
    "APIM_GATEWAY_URL=<set-after-manual-create>",
    "APIM_API_ID=<set-after-manual-create>",
    "GOOD_APP_SUBSCRIPTION_KEY=<set-after-subscription-create>",
    "ROGUE_APP_SUBSCRIPTION_KEY=<set-after-subscription-create>",
    "APIM_BACKEND_SWEDEN_ID=foundry-sweden-central",
    "APIM_BACKEND_FRANCE_ID=foundry-france-central",
    "APIM_BACKEND_NORTH_ID=foundry-north-europe"
)

foreach ($project in $foundryProjects) {
    $regionToken = $project.Region.ToUpper().Replace(" ", "_")
    $chatEndpoint = "$($project.ProjectEndpoint)/openai/deployments/$($project.DeploymentName)/chat/completions?api-version=2024-10-21"

    $envLines += "FOUNDRY_${regionToken}_PROJECT_NAME=$($project.ProjectName)"
    $envLines += "FOUNDRY_${regionToken}_PROJECT_ID=$($project.ProjectId)"
    $envLines += "FOUNDRY_${regionToken}_HUB_NAME=$($project.AccountName)"
    $envLines += "FOUNDRY_${regionToken}_HUB_ID=$($project.AccountId)"
    $envLines += "FOUNDRY_${regionToken}_PROJECT_ENDPOINT=$($project.ProjectEndpoint)"
    $envLines += "FOUNDRY_${regionToken}_PROJECT_KEY=$($project.ProjectKey)"
    $envLines += "FOUNDRY_${regionToken}_DEPLOYMENT=$($project.DeploymentName)"
    $envLines += "FOUNDRY_${regionToken}_CHAT_COMPLETIONS_URL=$chatEndpoint"
    $envLines += "FOUNDRY_${regionToken}_DEPLOYMENT_STATUS=$($project.DeploymentStatus)"
}

if (-not [string]::IsNullOrWhiteSpace($functionAppName)) {
    $envLines += "FUNCTION_APP_NAME=$functionAppName"
    $envLines += "FUNCTION_BASE_URL=$functionBaseUrl"
}

Set-Content -Path $envPath -Value $envLines -Encoding UTF8

Write-Host "Provisioning complete."
Write-Host "Environment file: $envPath"
$foundryProjects | ForEach-Object {
    Write-Host ("{0}: account={1}; project={2}; endpoint={3}; deployment={4}" -f $_.Region, $_.AccountName, $_.ProjectName, $_.ProjectEndpoint, $_.DeploymentStatus)
}
if ($IncludeFunctions.IsPresent) {
    Write-Host "Function App URL: $functionBaseUrl"
}
