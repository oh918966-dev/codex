# Red-Team Drill Guide (Lightweight)

This guide verifies that the agent interrupts unsafe operations after deployment.

## 1. What is covered

- Prompt injection attempts (disable/bypass risk checks)
- Oversized order attempts
- Non-whitelisted source IP
- Withdraw requests when withdraw is disabled
- A normal safe scenario for control validation

## 2. Files

- Agent simulator: `scripts/agent-simulator.ps1`
- Drill runner: `scripts/red-team-drill.ps1`
- Scenarios: `config/red-team-scenarios.json`
- Baseline: `config/security-baseline.json`

## 3. Run

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\red-team-drill.ps1
```

Expected: all malicious scenarios return `ABORTED`; safe scenario returns `ALLOWED`.

## 4. Add your own attack cases

Append to `config/red-team-scenarios.json` with fields:

- `name`
- `symbol`
- `order_pct`
- `source_ip`
- `requires_withdraw`
- `force_live`
- `attack_prompt`
- `expected_status`

## 5. CI suggestion

Use the drill as a deployment gate:

- Run `daily-security-check.ps1`
- Run `red-team-drill.ps1`
- Block release if either script fails
