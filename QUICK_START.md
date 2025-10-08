# Quick Start Guide

## Deploy to 192.168.66.3

```bash
export SSHPASS='1234@Qwer'
./scripts/deployment/deploy.sh
```

**That's it!** The script handles everything:
- ✅ Syncs codebase
- ✅ Configures logging
- ✅ Restarts server
- ✅ Verifies deployment

---

## View Logs

```bash
# From anywhere:
curl http://192.168.66.3:9000/logs?lines=50 | jq -r '.logs'

# Real-time monitoring:
watch -n 2 'curl -s http://192.168.66.3:9000/logs?lines=20 | jq -r .logs | tail -10'
```

---

## Test Tony Agent

Tony is now using the 66.3 server. All operations are logged.

**Test it**:
```
"Tony, get issue FE-56"
"Tony, create a task in project FE"
"Tony, update FE-152 with [your content]"
```

**Then check logs**:
```bash
curl http://192.168.66.3:9000/logs?lines=100 | jq -r '.logs' | grep FE-
```

---

## Important Limits

### Content Size (with GPT-5)
- ✅ **< 1,000 chars**: 100% reliable
- ✅ **1,000-3,000 chars**: 95%+ preserved
- ⚠️ **3,000-5,000 chars**: ~70% preserved
- ❌ **> 5,000 chars**: Use Jira UI instead

### Performance
- **Create/Update**: 2-5 seconds
- **Read**: < 2 seconds
- **Timeout**: None observed (GPT-5 fix)

---

## Documentation

**Need more details?**
- Deployment: `docs/deployment/`
- Troubleshooting: `docs/n8n-fix/TIMEOUT_ANALYSIS_AND_SOLUTION.md`
- Tony validation: `docs/deployment/TONY_66.3_VALIDATION_REPORT.md`
- Full docs index: `docs/README.md`

---

**Server Status**: http://192.168.66.3:9000/healthz
**Public Logs**: http://192.168.66.3:9000/logs
**Latest Deploy**: 2025-10-08 (commit 72911fc)
