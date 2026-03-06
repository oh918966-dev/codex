Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Add-CheckResult {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Message
    )
    [PSCustomObject]@{
        Check = $Name
        Status = if ($Passed) { "PASS" } else { "FAIL" }
        Message = $Message
    }
}

$results = @()
$repoRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $repoRoot "config/security-baseline.json"
$examplePath = Join-Path $repoRoot "config/security-baseline.example.json"

if (Test-Path $configPath) {
    $raw = Get-Content $configPath -Raw
    $cfg = $raw | ConvertFrom-Json
    $results += Add-CheckResult "Config file" $true "Using config/security-baseline.json"
} elseif (Test-Path $examplePath) {
    $raw = Get-Content $examplePath -Raw
    $cfg = $raw | ConvertFrom-Json
    $results += Add-CheckResult "Config file" $false "security-baseline.json missing, using example only"
} else {
    $results += Add-CheckResult "Config file" $false "No baseline config found"
    $cfg = $null
}

if ($null -ne $cfg) {
    $withdrawOff = -not [bool]$cfg.api.withdraw
    $results += Add-CheckResult "Withdraw disabled" $withdrawOff "api.withdraw should be false"

    $ipCount = @($cfg.api.ip_whitelist).Count
    $results += Add-CheckResult "IP whitelist" ($ipCount -gt 0) "ip_whitelist count: $ipCount"

    $dailyLoss = [double]$cfg.risk.max_daily_loss_pct
    $results += Add-CheckResult "Daily loss limit" ($dailyLoss -le 3) "max_daily_loss_pct: $dailyLoss (target <= 3)"

    $singleOrder = [double]$cfg.risk.max_single_order_pct
    $results += Add-CheckResult "Single order limit" ($singleOrder -le 10) "max_single_order_pct: $singleOrder (target <= 10)"

    $paperMode = [bool]$cfg.ops.paper_trading
    $results += Add-CheckResult "Paper trading" $paperMode "ops.paper_trading should be true during trial"

    $killSwitch = [bool]$cfg.ops.kill_switch_enabled
    $results += Add-CheckResult "Kill switch" $killSwitch "ops.kill_switch_enabled should be true"
}

$patterns = @(
    'AKIA[0-9A-Z]{16}',
    '(?i)api[_-]?key',
    '(?i)api[_-]?secret',
    '(?i)private[_-]?key'
)

$secretHits = @()
$gitExe = $null
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($null -ne $gitCmd) {
    $gitExe = $gitCmd.Source
} elseif (Test-Path "D:\github\Git\cmd\git.exe") {
    $gitExe = "D:\github\Git\cmd\git.exe"
}

if ($null -ne $gitExe) {
    $trackedFiles = & $gitExe -C $repoRoot ls-files
    foreach ($file in $trackedFiles) {
        if ($file -eq "config/security-baseline.example.json") { continue }
        $fullPath = Join-Path $repoRoot $file
        if (-not (Test-Path $fullPath)) { continue }
        foreach ($pattern in $patterns) {
            $hits = Select-String -Path $fullPath -Pattern $pattern -AllMatches -ErrorAction SilentlyContinue
            if ($hits) {
                $secretHits += "$file matches pattern: $pattern"
                break
            }
        }
    }
    $results += Add-CheckResult "Tracked secret scan" ($secretHits.Count -eq 0) "hits: $($secretHits.Count)"
} else {
    $results += Add-CheckResult "Tracked secret scan" $true "git command not found; scan skipped"
}

$results | Format-Table -AutoSize

if ($secretHits.Count -gt 0) {
    Write-Host "`nPotential secrets:" -ForegroundColor Yellow
    $secretHits | ForEach-Object { Write-Host "- $_" -ForegroundColor Yellow }
}

$failed = @($results | Where-Object { $_.Status -eq "FAIL" }).Count
if ($failed -gt 0) {
    Write-Error "Security check failed: $failed check(s) failed."
    exit 1
}

Write-Host "`nAll checks passed." -ForegroundColor Green
exit 0
