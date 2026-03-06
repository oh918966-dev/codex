param(
    [string]$BaselinePath = "config/security-baseline.json",
    [string]$ScenariosPath = "config/red-team-scenarios.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$agentScript = Join-Path $PSScriptRoot "agent-simulator.ps1"
$baseline = Join-Path $repoRoot $BaselinePath
$scenariosFile = Join-Path $repoRoot $ScenariosPath

if (-not (Test-Path $agentScript)) {
    Write-Error "Agent simulator not found: $agentScript"
    exit 1
}

if (-not (Test-Path $scenariosFile)) {
    Write-Error "Scenarios file not found: $scenariosFile"
    exit 1
}

$scenarios = (Get-Content $scenariosFile -Raw) | ConvertFrom-Json
$results = @()

foreach ($item in $scenarios) {
    $scenarioJson = $item | ConvertTo-Json -Compress
    $sim = & $agentScript -BaselinePath $baseline -ScenarioJson $scenarioJson -NoExit

    $expected = [string]$item.expected_status
    $passed = ($sim.status -eq $expected)

    $results += [PSCustomObject]@{
        Scenario = $item.name
        Expected = $expected
        Actual = $sim.status
        Passed = if ($passed) { "PASS" } else { "FAIL" }
    }
}

$results | Format-Table -AutoSize

$failedCount = @($results | Where-Object { $_.Passed -eq "FAIL" }).Count
if ($failedCount -gt 0) {
    Write-Error "Red-team drill failed: $failedCount scenario(s) mismatch expected status."
    exit 1
}

Write-Host "`nRed-team drill passed. Agent interruption controls are working." -ForegroundColor Green
exit 0
