# OpenClaw/Exchange Light Security Practice (10-minute version)

This checklist is for personal or small-scale crypto trading automation.
Goal: reduce catastrophic risk before any real trading.

## 1. Account and API permissions (must do)

1. Create a dedicated exchange sub-account for the bot.
2. Create API key with only `Read` + `Trade`.
3. Ensure `Withdraw` permission is OFF.
4. Add fixed IP whitelist for the API key.
5. Enable 2FA on the main account and email.

## 2. Trading limits (must do)

1. Set max single-order exposure <= 10% of account equity.
2. Set max daily loss <= 3% of account equity.
3. Set max open positions <= 3.
4. Restrict allowed symbols by whitelist (example: `SOLUSDT`, `ETHUSDT`).
5. Block low-liquidity assets unless manually approved.

## 3. Deployment baseline (must do)

1. Keep keys in environment variables; never commit to git.
2. Keep `paper_trading=true` until 7-14 days of stable logs.
3. Use stop-loss and emergency kill-switch.
4. Keep logs for orders, errors, and risk stops.
5. Configure alert channel (Telegram/Slack/Email).

## 4. Daily quick audit (2-3 minutes)

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\daily-security-check.ps1
```

Pass conditions:

- No withdraw permission in baseline file
- API IP whitelist is not empty
- Daily loss limit <= 3%
- Position size limit <= 10%
- Paper trading mode enabled (for trial stage)
- No obvious secrets in tracked files

## 5. Go-live gate (before real money)

Only switch to real trading when all are true:

1. At least 7 days of paper-trading logs.
2. No unresolved high-risk findings in daily checks.
3. You can manually stop bot and cancel all orders quickly.
4. You understand max potential loss for one day.

## 6. What this guide does not cover

- Smart contract audit
- On-chain MEV protection
- Institutional custody workflows

Use this as minimum baseline, then expand controls gradually.
