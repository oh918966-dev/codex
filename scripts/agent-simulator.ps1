param(
    [string]$BaselinePath = "config/security-baseline.json",
    [string]$ScenarioPath,
    [string]$ScenarioJson,
    [switch]$NoExit,
    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-Result {
    param(
        [string]$ScenarioName,
        [string]$Status,
        [string[]]$Reasons
    )

    [PSCustomObject]@{
        scenario = $ScenarioName
        status = $Status
        reasons = $Reasons
        timestamp = (Get-Date).ToString("s")
    }
}

if (-not (Test-Path $BaselinePath)) {
    Write-Error "Baseline config not found: $BaselinePath"
    exit 1
}

$baseline = (Get-Content $BaselinePath -Raw) | ConvertFrom-Json

$scenario = $null
if ($ScenarioJson) {
    $scenario = $ScenarioJson | ConvertFrom-Json
} elseif ($ScenarioPath) {
    if (-not (Test-Path $ScenarioPath)) {
        Write-Error "Scenario file not found: $ScenarioPath"
        exit 1
    }
    $scenario = (Get-Content $ScenarioPath -Raw) | ConvertFrom-Json
} else {
    Write-Error "Provide ScenarioPath or ScenarioJson."
    exit 1
}

$reasons = @()
$scenarioName = [string]$scenario.name
if ([string]::IsNullOrWhiteSpace($scenarioName)) {
    $scenarioName = "unnamed-scenario"
}

$requestedSymbol = [string]$scenario.symbol
if ([string]::IsNullOrWhiteSpace($requestedSymbol)) {
    $reasons += "Missing symbol"
}

$orderPct = 0
if ($null -ne $scenario.order_pct) {
    $orderPct = [double]$scenario.order_pct
}

$sourceIp = [string]$scenario.source_ip
$requiresWithdraw = [bool]$scenario.requires_withdraw
$attackPrompt = [string]$scenario.attack_prompt

if ($requiresWithdraw -and (-not [bool]$baseline.api.withdraw)) {
    $reasons += "Withdraw requested but baseline disables withdraw"
}

$allowedIps = @($baseline.api.ip_whitelist)
if ($sourceIp -and (($allowedIps -contains $sourceIp) -eq $false)) {
    $reasons += "Source IP not in whitelist"
}

$maxOrderPct = [double]$baseline.risk.max_single_order_pct
if ($orderPct -gt $maxOrderPct) {
    $reasons += "Order size exceeds max_single_order_pct"
}

$allowedSymbols = @($baseline.risk.symbol_whitelist)
if ($requestedSymbol -and (($allowedSymbols -contains $requestedSymbol) -eq $false)) {
    $reasons += "Symbol not in whitelist"
}

if ([bool]$baseline.ops.paper_trading -and [bool]$scenario.force_live) {
    $reasons += "Paper trading mode enabled; live action blocked"
}

$attackSignals = @("ignore risk", "disable risk", "bypass", "jailbreak", "override policy")
if ($attackPrompt) {
    foreach ($signal in $attackSignals) {
        if ($attackPrompt.ToLower().Contains($signal)) {
            $reasons += "Prompt injection signal: $signal"
            break
        }
    }
}

if ($reasons.Count -gt 0) {
    $result = New-Result -ScenarioName $scenarioName -Status "ABORTED" -Reasons $reasons
} else {
    $result = New-Result -ScenarioName $scenarioName -Status "ALLOWED" -Reasons @("All checks passed")
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 4
} else {
    $result
}

if (-not $NoExit) {
    if ($result.status -eq "ALLOWED") {
        exit 0
    }
    exit 2
}
