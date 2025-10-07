"""Tests for JSON string parameter support in Jira MCP server tools."""

import json

import pytest
from mcp_atlassian.servers.jira import create_issue, update_issue, transition_issue


@pytest.mark.asyncio
async def test_create_issue_with_json_string_additional_fields(
    mock_jira_context, mock_jira_issue
):
    """Test create_issue accepts additional_fields as JSON string."""
    # Prepare JSON string for additional_fields
    additional_fields_json = json.dumps(
        {"priority": {"name": "High"}, "labels": ["frontend", "urgent"]}
    )

    # Mock the jira fetcher to return a mock issue
    mock_jira_context.jira.create_issue.return_value = mock_jira_issue

    # Call create_issue with JSON string
    result = await create_issue(
        ctx=mock_jira_context,
        project_key="TEST",
        summary="Test Issue",
        issue_type="Task",
        additional_fields=additional_fields_json,
    )

    # Verify the result is valid JSON
    result_dict = json.loads(result)
    assert result_dict["message"] == "Issue created successfully"
    assert "issue" in result_dict


@pytest.mark.asyncio
async def test_create_issue_with_dict_additional_fields(
    mock_jira_context, mock_jira_issue
):
    """Test create_issue still accepts additional_fields as dict."""
    # Prepare dict for additional_fields
    additional_fields_dict = {"priority": {"name": "High"}, "labels": ["frontend"]}

    # Mock the jira fetcher to return a mock issue
    mock_jira_context.jira.create_issue.return_value = mock_jira_issue

    # Call create_issue with dict
    result = await create_issue(
        ctx=mock_jira_context,
        project_key="TEST",
        summary="Test Issue",
        issue_type="Task",
        additional_fields=additional_fields_dict,
    )

    # Verify the result is valid JSON
    result_dict = json.loads(result)
    assert result_dict["message"] == "Issue created successfully"


@pytest.mark.asyncio
async def test_create_issue_with_invalid_json_string(mock_jira_context):
    """Test create_issue rejects invalid JSON string."""
    # Prepare invalid JSON string
    invalid_json = "{'priority': 'High'}"  # Single quotes are invalid JSON

    # Should raise ValueError
    with pytest.raises(ValueError, match="additional_fields must be a valid JSON string"):
        await create_issue(
            ctx=mock_jira_context,
            project_key="TEST",
            summary="Test Issue",
            issue_type="Task",
            additional_fields=invalid_json,
        )


@pytest.mark.asyncio
async def test_update_issue_with_json_string_fields(
    mock_jira_context, mock_jira_issue
):
    """Test update_issue accepts fields as JSON string."""
    # Prepare JSON strings
    fields_json = json.dumps({"summary": "Updated Summary"})
    additional_fields_json = json.dumps({"priority": {"name": "Low"}})

    # Mock the jira fetcher
    mock_jira_context.jira.update_issue.return_value = mock_jira_issue

    # Call update_issue with JSON strings
    result = await update_issue(
        ctx=mock_jira_context,
        issue_key="TEST-123",
        fields=fields_json,
        additional_fields=additional_fields_json,
    )

    # Verify the result
    result_dict = json.loads(result)
    assert result_dict["message"] == "Issue updated successfully"


@pytest.mark.asyncio
async def test_transition_issue_with_json_string_fields(
    mock_jira_context, mock_jira_issue
):
    """Test transition_issue accepts fields as JSON string."""
    # Prepare JSON string
    fields_json = json.dumps({"resolution": {"name": "Fixed"}})

    # Mock the jira fetcher
    mock_jira_context.jira.transition_issue.return_value = mock_jira_issue

    # Call transition_issue with JSON string
    result = await transition_issue(
        ctx=mock_jira_context,
        issue_key="TEST-123",
        transition_id="5",
        fields=fields_json,
    )

    # Verify the result
    result_dict = json.loads(result)
    assert "message" in result_dict
    assert "transitioned successfully" in result_dict["message"]


@pytest.mark.asyncio
async def test_n8n_compatibility_scenario(mock_jira_context, mock_jira_issue):
    """Test typical n8n usage scenario with JSON strings."""
    # Simulate n8n sending additional_fields as a JSON string
    # This is the most common issue reported by users
    additional_fields = json.dumps(
        {
            "priority": {"name": "High"},
            "labels": ["n8n-automation", "high-priority"],
            "customfield_10010": "Epic Link Value",
            "fixVersions": [{"name": "v1.0"}],
        }
    )

    # Mock the jira fetcher
    mock_jira_context.jira.create_issue.return_value = mock_jira_issue

    # This should NOT raise an error
    result = await create_issue(
        ctx=mock_jira_context,
        project_key="PROJ",
        summary="Created from n8n",
        issue_type="Task",
        description="This issue was created via n8n automation",
        additional_fields=additional_fields,
    )

    # Verify successful creation
    result_dict = json.loads(result)
    assert result_dict["message"] == "Issue created successfully"
    assert "issue" in result_dict
