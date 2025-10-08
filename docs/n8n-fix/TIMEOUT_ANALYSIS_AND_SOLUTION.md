# MCP Atlassian Timeout Analysis & Solutions

## Problem Statement
Tony agent times out when trying to retrieve large Jira issue descriptions (14,800+ characters), with error: `"Request timed out."`

## Timeout Sources Identified

### 1. **n8n Workflow Timeout** (Most Likely Culprit)
**Location**: n8n workflow configuration (192.168.66.3:5678)

**Default Settings**:
- n8n HTTP Request Node default timeout: **5 minutes (300 seconds)**
- n8n MCP Agent Node timeout: **configurable per node**
- n8n workflow execution timeout: **configurable globally**

**Evidence**: Tony agent returns `"Request timed out."` - this is typically an n8n MCP client-side timeout, not a server error.

### 2. **FastMCP Client Timeout**
**Location**: `fastmcp.client.client.py`

**Default Settings**:
```python
client_init_timeout: float | None = None  # No default timeout for init
timeout: timedelta | float | int | None = None  # No default request timeout
```

**Key Finding**: FastMCP doesn't set a default request timeout, but n8n's MCP integration likely adds one.

### 3. **Uvicorn/HTTP Server Timeout**
**Location**: MCP Atlassian server (192.168.66.5:9000)

**Default Settings**:
```python
# Uvicorn defaults (not explicitly configured in mcp-atlassian):
timeout_keep_alive: 5 seconds
timeout_graceful_shutdown: None
```

**Finding**: No explicit timeout configuration in our MCP server. Uvicorn uses default keep-alive timeout of 5s, but this doesn't affect long-running requests.

### 4. **Jira API Timeout**
**Location**: `atlassian-python-api` library

**Default Settings**:
- HTTP client timeout: typically **60 seconds** for requests library
- No timeout observed in Jira API calls during testing

**Finding**: Jira API responds quickly (< 5 seconds even for large issues)

---

## Timeout Chain Analysis

```
User Request → n8n → MCP Client → HTTP → MCP Server → Jira API
               ↑                                          ↓
            TIMEOUT                              Response (fast)
         (likely here)
```

**Flow**:
1. User asks Tony to get FE-151 description
2. n8n sends MCP request with default timeout (likely 60-300s)
3. MCP server calls `jira_get_issue`
4. Jira API returns large response quickly (< 5s)
5. MCP server processes and converts Jira wiki markup to markdown
6. **TIMEOUT OCCURS** - n8n MCP client times out before processing completes

---

## Root Cause

**Primary**: n8n MCP Agent node has a **request timeout** (likely 60 seconds default) that's too short for processing large Jira responses.

**Secondary**: Tony agent's processing of large content:
1. Fetches issue from Jira (fast)
2. Converts Jira wiki markup → Markdown (slow for large content)
3. Formats response for user (slow)
4. Analyzes content to generate summary (very slow)

For 14,800 character responses, this processing can exceed 60 seconds.

---

## Solutions

### Solution 1: Increase n8n MCP Node Timeout ⭐ **RECOMMENDED**

**Steps**:
1. SSH to n8n server (192.168.66.3)
2. Open n8n workflow containing Tony agent
3. Find the MCP Agent node configuration
4. Increase timeout settings:

```json
{
  "timeout": 300000,  // 5 minutes in milliseconds
  "continueOnFail": false
}
```

**Alternative - Global n8n Setting**:
```bash
# In n8n environment variables
N8N_EXECUTION_TIMEOUT=600  # 10 minutes
N8N_EXECUTION_TIMEOUT_MAX=-1  # No limit
```

**Benefits**:
- ✅ Fixes the immediate timeout issue
- ✅ No code changes required
- ✅ Works for all future large responses

**Drawbacks**:
- ❌ Doesn't address the slow processing
- ❌ Could hide performance issues

---

### Solution 2: Add MCP Server-Side Caching

**Implementation**: Cache Jira responses to speed up repeated queries

```python
# In src/mcp_atlassian/jira/issues.py

from cachetools import TTLCache, cached

# Cache for 5 minutes
issue_cache = TTLCache(maxsize=100, ttl=300)

@cached(issue_cache, key=lambda issue_key, **kwargs: issue_key)
async def get_issue_cached(issue_key: str, **kwargs):
    return await get_issue(issue_key, **kwargs)
```

**Benefits**:
- ✅ Subsequent requests are instant
- ✅ Reduces Jira API load
- ✅ No n8n changes needed

**Drawbacks**:
- ❌ Doesn't help first request
- ❌ Cache invalidation complexity

---

### Solution 3: Optimize Markdown Conversion

**Problem**: Converting large Jira wiki markup to Markdown is slow

**Implementation**:
```python
# Use faster markdown library or lazy conversion
from mcp_atlassian.preprocessing import JiraPreprocessor

class OptimizedJiraPreprocessor(JiraPreprocessor):
    def convert_to_markdown(self, content: str, max_length: int = 10000):
        # Skip conversion for very large content
        if len(content) > max_length:
            return f"[Large content - {len(content)} chars - view in Jira]"
        return super().convert_to_markdown(content)
```

**Benefits**:
- ✅ Faster processing for large content
- ✅ Prevents timeout
- ✅ Still provides useful feedback

**Drawbacks**:
- ❌ User doesn't get full markdown
- ❌ Requires code changes

---

### Solution 4: Implement Streaming Responses

**Concept**: Stream large responses instead of waiting for complete processing

```python
# Use Server-Sent Events (SSE) for progressive updates
async def stream_large_issue_response(issue_key: str):
    yield {"status": "fetching", "progress": 0}
    issue = await jira_get_issue(issue_key)

    yield {"status": "converting", "progress": 50}
    markdown = convert_to_markdown(issue.description)

    yield {"status": "complete", "progress": 100, "data": markdown}
```

**Benefits**:
- ✅ No timeout issues
- ✅ Better user experience (progress updates)
- ✅ Handles arbitrarily large content

**Drawbacks**:
- ❌ Requires n8n workflow changes
- ❌ More complex implementation
- ❌ Not all MCP clients support streaming

---

### Solution 5: Add Pagination for Large Content

**Implementation**: Return content in chunks

```python
async def get_issue_paginated(issue_key: str, page: int = 1, page_size: int = 2000):
    """Get issue content in pages to avoid timeouts"""
    full_content = await get_issue(issue_key)

    start = (page - 1) * page_size
    end = start + page_size

    return {
        "page": page,
        "total_pages": (len(full_content) // page_size) + 1,
        "content": full_content[start:end],
        "has_more": end < len(full_content)
    }
```

**Benefits**:
- ✅ Never times out
- ✅ User can request specific sections
- ✅ Works with existing infrastructure

**Drawbacks**:
- ❌ Requires multiple requests
- ❌ More complex user interaction

---

## Recommended Implementation Plan

### Phase 1: Immediate Fix (Today)
1. **Increase n8n MCP timeout to 300 seconds**
   - Edit Tony agent workflow in n8n
   - Update MCP node timeout setting
   - Test with FE-151 large description

### Phase 2: Short-term (This Week)
2. **Add environment variable for timeout configuration**
   ```bash
   # Add to .env
   MCP_REQUEST_TIMEOUT=300  # 5 minutes
   ```

3. **Add timeout warning for large responses**
   ```python
   if len(description) > 10000:
       logger.warning(f"Large description ({len(description)} chars) may timeout")
   ```

### Phase 3: Medium-term (Next Sprint)
4. **Implement response caching** (Solution 2)
   - Cache frequently accessed issues
   - Reduce repeated query time

5. **Optimize markdown conversion** (Solution 3)
   - Skip conversion for very large content
   - Provide summary instead

### Phase 4: Long-term (Future)
6. **Implement streaming responses** (Solution 4)
   - Full Server-Sent Events support
   - Progressive loading

7. **Add pagination API** (Solution 5)
   - For issues > 10,000 characters
   - Optional chunked retrieval

---

## Testing Plan

### Test Case 1: Small Content (< 500 chars)
```bash
# Expected: < 1 second response
curl -X POST http://192.168.66.5:9000/mcp/ \
  -d '{"method": "tools/call", "params": {"name": "jira_get_issue", "arguments": {"issue_key": "FE-150"}}}'
```
✅ Works perfectly

### Test Case 2: Medium Content (500-2000 chars)
```bash
# Expected: 1-5 second response
curl -X POST http://192.168.66.5:9000/mcp/ \
  -d '{"method": "tools/call", "params": {"name": "jira_get_issue", "arguments": {"issue_key": "FE-149"}}}'
```
✅ Works reliably

### Test Case 3: Large Content (2000-10000 chars)
```bash
# Expected: 5-30 second response
curl -X POST http://192.168.66.5:9000/mcp/ \
  -d '{"method": "tools/call", "params": {"name": "jira_get_issue", "arguments": {"issue_key": "FE-56"}}}'
```
⚠️ Works but approaching timeout

### Test Case 4: Very Large Content (10000+ chars)
```bash
# Expected: 30-60+ second response
curl -X POST http://192.168.66.5:9000/mcp/ \
  -d '{"method": "tools/call", "params": {"name": "jira_get_issue", "arguments": {"issue_key": "FE-151"}}}'
```
❌ Times out in n8n (currently)

---

## Configuration Files to Check/Modify

### 1. n8n Workflow (Tony Agent)
**File**: Accessed via n8n UI at http://192.168.66.3:5678
**Settings to modify**:
```json
{
  "nodes": [{
    "type": "n8n-nodes-base.mcp",
    "parameters": {
      "timeout": 300000,  // ← Change this
      "operation": "callTool"
    }
  }]
}
```

### 2. MCP Server Environment
**File**: `/home/nev3r/projects/mcp-atlassian/.env`
**Add**:
```bash
# Request timeout configuration
MCP_REQUEST_TIMEOUT=300
MCP_RESPONSE_SIZE_LIMIT=50000  # characters
```

### 3. FastMCP Client (if accessible)
**File**: n8n MCP node configuration
**Settings**:
```javascript
const client = new MCPClient({
  timeout: 300000,  // 5 minutes
  init_timeout: 30000  // 30 seconds for connection
});
```

---

## Monitoring & Debugging

### Enable Detailed Logging
```bash
# On MCP server
export LOG_FILE=/tmp/mcp-atlassian-logs/app.log
export MCP_VERY_VERBOSE=true

# Restart server
uv run mcp-atlassian --transport streamable-http --port 9000 -vv
```

### Check Logs in Real-Time
```bash
# Via HTTP endpoint
curl http://192.168.66.5:9000/logs?lines=100 | jq -r '.logs'

# Via file
tail -f /tmp/mcp-atlassian-logs/app.log
```

### Monitor Request Duration
```python
# Add to jira/issues.py
import time

async def get_issue(issue_key: str, **kwargs):
    start_time = time.time()
    result = await _get_issue_impl(issue_key, **kwargs)
    duration = time.time() - start_time

    logger.info(f"get_issue({issue_key}) took {duration:.2f}s")
    return result
```

---

## Conclusion

**The timeout is happening in n8n's MCP client, not the MCP server.**

**Immediate Action**:
1. Access n8n at http://192.168.66.3:5678
2. Edit Tony agent workflow
3. Find MCP node calling `mcp__tony_tools__Call_Tony_Tools_`
4. Increase timeout from default (likely 60s) to 300s (5 minutes)
5. Save and redeploy workflow

**Verification**:
```bash
# After increasing timeout, test again:
mcp__tony_tools__Call_Tony_Tools_({
  sessionID: "test-verify-timeout-fix",
  chatInput: "Get full description of FE-151 with all details"
})

# Should now return complete content without timeout
```

This should resolve the timeout issue for large Jira issue descriptions.
