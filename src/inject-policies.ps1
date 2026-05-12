param(
    [Parameter(Mandatory = $true)]
    [string]$ApimName,

    [Parameter(Mandatory = $true)]
    [string]$ApiId,

    [string]$ResourceGroupName = "rg-inRiverAIGW",

    [ValidateSet("load-balancer-pool", "smart-routing", "rate-limit", "token-quota", "enterprise-jwt-credits")]
    [string]$PolicyName = "load-balancer-pool",

    [string]$OperationId,

    [string]$PoliciesDirectory = (Join-Path $PSScriptRoot "apim-policies"),
    [string]$ModelDeployment = "gpt-5.2"
)

$ErrorActionPreference = "Stop"
$policyFile = Join-Path $PoliciesDirectory ("{0}.xml" -f $PolicyName)

if (-not (Test-Path $policyFile)) {
    throw "Policy file not found: $policyFile"
}

$secUrl = "https://inriver-aigw-foundry-sec.openai.azure.com/openai/deployments/$ModelDeployment/chat/completions?api-version=2024-10-21"
$frcUrl = "https://inriver-aigw-foundry-frc.openai.azure.com/openai/deployments/$ModelDeployment/chat/completions?api-version=2024-10-21"
$espUrl = "https://inriver-aigw-foundry-esp.openai.azure.com/openai/deployments/$ModelDeployment/chat/completions?api-version=2024-10-21"

$xmlContent = Get-Content -Path $policyFile -Raw
$xmlContent = $xmlContent.Replace("https://inriver-aigw-foundry-sec.openai.azure.com/openai/deployments/gpt-5.2/chat/completions?api-version=2024-10-21", $secUrl)
$xmlContent = $xmlContent.Replace("https://inriver-aigw-foundry-frc.openai.azure.com/openai/deployments/gpt-5.2/chat/completions?api-version=2024-10-21", $frcUrl)
$xmlContent = $xmlContent.Replace("https://inriver-aigw-foundry-esp.openai.azure.com/openai/deployments/gpt-5.2/chat/completions?api-version=2024-10-21", $espUrl)

Write-Host "Applying policy '$PolicyName' from $policyFile"

if ([string]::IsNullOrWhiteSpace($OperationId)) {
    try {
        az apim api policy create `
            --resource-group $ResourceGroupName `
            --service-name $ApimName `
            --api-id $ApiId `
            --xml-content $xmlContent `
            --only-show-errors | Out-Null
    }
    catch {
        az apim api policy update `
            --resource-group $ResourceGroupName `
            --service-name $ApimName `
            --api-id $ApiId `
            --xml-content $xmlContent `
            --only-show-errors | Out-Null
    }
}
else {
    try {
        az apim api operation policy create `
            --resource-group $ResourceGroupName `
            --service-name $ApimName `
            --api-id $ApiId `
            --operation-id $OperationId `
            --xml-content $xmlContent `
            --only-show-errors | Out-Null
    }
    catch {
        az apim api operation policy update `
            --resource-group $ResourceGroupName `
            --service-name $ApimName `
            --api-id $ApiId `
            --operation-id $OperationId `
            --xml-content $xmlContent `
            --only-show-errors | Out-Null
    }
}

Write-Host "Policy '$PolicyName' applied successfully."