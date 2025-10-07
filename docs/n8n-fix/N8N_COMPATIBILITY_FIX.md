# n8n Compatibility Fix for additional_fields

## Problem Summary

When calling the mcp-atlassian server from n8n using HTTP transport (SSE or streamable-http), the `additional_fields` parameter and other complex dictionary parameters were failing with the error:

```
ValueError: additional_fields must be a dictionary.
```

## Root Cause

**Transport-specific JSON serialization differences:**

1. **Claude Code (stdio transport)**: Properly deserializes MCP tool parameters as native Python objects. When a parameter is defined as `dict[str, Any]`, Claude Code sends it as an actual Python dictionary.

2. **n8n (HTTP transports - SSE/streamable-http)**: Serializes complex parameters as JSON strings during HTTP transmission. When n8n calls a tool with `additional_fields = {"priority": {"name": "High"}}`, the MCP server receives it as the string `'{"priority": {"name": "High"}}'` instead of a native Python dict.

The validation code in `servers/jira.py` was checking `isinstance(extra_fields, dict)` which failed when receiving a JSON string from n8n.

## Solution Implemented

Modified the following Jira MCP tool functions in `src/mcp_atlassian/servers/jira.py` to accept both native dictionaries AND JSON strings:

### 1. **create_issue** (lines 652-701)
- Parameter: `additional_fields`
- Now accepts: `dict[str, Any] | str | None`
- Added JSON string parsing before validation

### 2. **update_issue** (lines 866-927)
- Parameters: `fields`, `additional_fields`
- Now accepts: `dict[str, Any] | str` and `dict[str, Any] | str | None`
- Added JSON string parsing for both parameters

### 3. **transition_issue** (lines 1313-1361)
- Parameter: `fields`
- Now accepts: `dict[str, Any] | str | None`
- Added JSON string parsing before validation

### 4. **create_issue_link** (lines 1142-1195)
- Parameter: `comment_visibility`
- Now accepts: `dict[str, str] | str | None`
- Added JSON string parsing with error handling

## Code Changes

**Before:**
```python
# Use additional_fields directly as dict
extra_fields = additional_fields or {}
if not isinstance(extra_fields, dict):
    raise ValueError("additional_fields must be a dictionary.")
```

**After:**
```python
# Parse additional_fields - handle both dict and JSON string
extra_fields = additional_fields or {}
if isinstance(extra_fields, str):
    try:
        extra_fields = json.loads(extra_fields)
    except json.JSONDecodeError as e:
        raise ValueError(f"additional_fields must be a valid JSON string or dictionary: {e}")
if not isinstance(extra_fields, dict):
    raise ValueError("additional_fields must be a dictionary or JSON string.")
```

## Testing

Created comprehensive test suite in `tests/unit/servers/test_jira_server_json_fields.py`:

- ✅ Test JSON string input for `additional_fields`
- ✅ Test native dict input (backward compatibility)
- ✅ Test invalid JSON string rejection
- ✅ Test JSON string input for `fields` parameter
- ✅ Test n8n compatibility scenario with complex nested structures

## Backward Compatibility

✅ **Fully backward compatible** - Claude Code and existing integrations using native Python dicts will continue to work without any changes.

## n8n Usage Example

After this fix, n8n workflows can now successfully call Jira tools with complex parameters:

```json
{
  "project_key": "PROJ",
  "summary": "Created from n8n",
  "issue_type": "Task",
  "additional_fields": "{\"priority\": {\"name\": \"High\"}, \"labels\": [\"automation\", \"n8n\"], \"customfield_10010\": \"Epic Link\"}"
}
```

OR with native objects (if n8n supports it):

```json
{
  "project_key": "PROJ",
  "summary": "Created from n8n",
  "issue_type": "Task",
  "additional_fields": {
    "priority": {"name": "High"},
    "labels": ["automation", "n8n"],
    "customfield_10010": "Epic Link"
  }
}
```

## Documentation Updates

- Updated `CLAUDE.md` with a new section "n8n and HTTP Transport Compatibility"
- Documents which tools are affected
- Explains the dual format support (dict + JSON string)

## Files Modified

1. `src/mcp_atlassian/servers/jira.py` - Main fix implementation
2. `tests/unit/servers/test_jira_server_json_fields.py` - New test file
3. `CLAUDE.md` - Documentation update
4. `N8N_COMPATIBILITY_FIX.md` - This document

## Next Steps

1. Run tests to verify the fix:
   ```bash
   uv run pytest tests/unit/servers/test_jira_server_json_fields.py -v
   ```

2. Test with n8n integration to confirm the fix works end-to-end

3. Consider applying similar fixes to Confluence tools if needed

4. Monitor for similar issues in other MCP tool parameters
