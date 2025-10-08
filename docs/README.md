# MCP Atlassian Documentation

This directory contains comprehensive documentation for the mcp-atlassian project.

## Directory Structure

```
docs/
├── README.md (this file)
├── deployment/          # Deployment guides and validation reports
└── n8n-fix/            # n8n integration analysis and fixes
```

---

## Deployment Documentation

### Location: `docs/deployment/`

**Deployment Guides**:
- [`MANUAL_DEPLOYMENT_66.3.md`](deployment/MANUAL_DEPLOYMENT_66.3.md) - Step-by-step manual deployment instructions
- [`DEPLOYMENT_SUMMARY.md`](deployment/DEPLOYMENT_SUMMARY.md) - Quick deployment overview and checklist
- [`DEPLOYMENT.md`](deployment/DEPLOYMENT.md) - General deployment instructions

**Validation Reports**:
- [`TONY_66.3_VALIDATION_REPORT.md`](deployment/TONY_66.3_VALIDATION_REPORT.md) - Complete Tony agent validation on 192.168.66.3

**Deployment Scripts**: See `scripts/deployment/`

---

## n8n Integration & Analysis

### Location: `docs/n8n-fix/`

**Core Analysis Documents**:
- [`TIMEOUT_ANALYSIS_AND_SOLUTION.md`](n8n-fix/TIMEOUT_ANALYSIS_AND_SOLUTION.md) - Timeout issue root cause analysis
- [`TONY_UPDATE_ISSUE_ANALYSIS.md`](n8n-fix/TONY_UPDATE_ISSUE_ANALYSIS.md) - Tony agent update behavior analysis
- [`FINAL_FINDINGS.md`](n8n-fix/FINAL_FINDINGS.md) - Comprehensive findings summary
- [`GPT5_IMPROVEMENT_RESULTS.md`](n8n-fix/GPT5_IMPROVEMENT_RESULTS.md) - GPT-5 vs previous model comparison

**Testing & Validation**:
- [`COMPLETE_AGENT_VALIDATION.md`](n8n-fix/COMPLETE_AGENT_VALIDATION.md) - Full agent validation results
- [`COMPREHENSIVE_TEST_REPORT.md`](n8n-fix/COMPREHENSIVE_TEST_REPORT.md) - Comprehensive testing report
- [`DETAILED_TEST_VALIDATION.md`](n8n-fix/DETAILED_TEST_VALIDATION.md) - Detailed test results
- [`FINAL_TEST_SUMMARY.md`](n8n-fix/FINAL_TEST_SUMMARY.md) - Final test summary
- [`AGENT_TEST_RESULTS.md`](n8n-fix/AGENT_TEST_RESULTS.md) - Agent-specific test results
- [`TEST_RESULTS.md`](n8n-fix/TEST_RESULTS.md) - General test results

**System Prompts & Configuration**:
- [`TONY_SYSTEM_PROMPT_OPTIMIZED.md`](n8n-fix/TONY_SYSTEM_PROMPT_OPTIMIZED.md) - Optimized Tony agent prompt
- [`TONY_SYSTEM_PROMPT.md`](n8n-fix/TONY_SYSTEM_PROMPT.md) - Original Tony system prompt
- [`LILY_SYSTEM_PROMPT_OPTIMIZED.md`](n8n-fix/LILY_SYSTEM_PROMPT_OPTIMIZED.md) - Optimized Lily agent prompt
- [`LILY_TEST_SCRIPT.md`](n8n-fix/LILY_TEST_SCRIPT.md) - Lily testing script

**Technical Documentation**:
- [`N8N_COMPATIBILITY_FIX.md`](n8n-fix/N8N_COMPATIBILITY_FIX.md) - n8n compatibility fixes
- [`PRODUCTION_DEPLOYMENT_REPORT.md`](n8n-fix/PRODUCTION_DEPLOYMENT_REPORT.md) - Production deployment report
- [`FIX_DOCUMENTATION_INDEX.md`](n8n-fix/FIX_DOCUMENTATION_INDEX.md) - Index of all fixes
- [`README.md`](n8n-fix/README.md) - n8n-fix directory overview

---

## Deployment Scripts

### Location: `scripts/deployment/`

**Available Scripts**:
- `deploy-66.3-final.sh` - **Recommended**: Full deployment with sshpass and verification
- `deploy-66.3.sh` - Alternative deployment script
- `deploy-to-66.3.sh` - Simple rsync deployment
- `deploy-with-sshpass.sh` - Generic sshpass deployment
- `setup-logs.sh` - Log directory setup utility

**Usage**:
```bash
# Deploy to 66.3
cd /home/nev3r/projects/mcp-atlassian
export SSHPASS='your-password'
./scripts/deployment/deploy-66.3-final.sh
```

---

## Quick Reference

### For Deployment
1. Read: `docs/deployment/MANUAL_DEPLOYMENT_66.3.md`
2. Run: `scripts/deployment/deploy-66.3-final.sh`
3. Verify: `docs/deployment/TONY_66.3_VALIDATION_REPORT.md`

### For Troubleshooting
1. Timeout issues: `docs/n8n-fix/TIMEOUT_ANALYSIS_AND_SOLUTION.md`
2. Tony updates: `docs/n8n-fix/TONY_UPDATE_ISSUE_ANALYSIS.md`
3. GPT-5 behavior: `docs/n8n-fix/GPT5_IMPROVEMENT_RESULTS.md`

### For Testing
1. Test results: `docs/n8n-fix/FINAL_TEST_SUMMARY.md`
2. Validation: `docs/deployment/TONY_66.3_VALIDATION_REPORT.md`
3. Agent configuration: `docs/n8n-fix/TONY_SYSTEM_PROMPT_OPTIMIZED.md`

---

## Related Documentation

- **Main README**: [`README.md`](../README.md) - Project overview and quick start
- **Contributing**: [`CONTRIBUTING.md`](../CONTRIBUTING.md) - Development guidelines
- **Claude Instructions**: [`CLAUDE.md`](../CLAUDE.md) - AI assistant guidance
- **Agents**: [`AGENTS.md`](../AGENTS.md) - Agent configuration details

---

## Recent Updates

**2025-10-08**:
- Added public logging support (HTTP /logs endpoint)
- Fixed file logging initialization timing
- Validated Tony agent on 192.168.66.3
- Confirmed GPT-5 improvements (67% content preservation)
- Organized all documentation

**Key Commits**:
- `c2c44c6` - fix: move file logging setup to correct location
- `7869382` - feat: add /logs endpoint for retrieving application logs
- `48fc904` - chore: remove deprecated main.json configuration

---

**Maintained by**: Claude Code
**Last Updated**: 2025-10-08
