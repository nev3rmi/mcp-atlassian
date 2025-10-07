# Lily Feature Test Script (Execute in n8n)

Use this script to test Lily's features directly in your n8n workflow.

---

## LILY FEATURE TEST - SECTION 1: Read & Analytics

**Test Lily in n8n with these prompts:**

### Test 1: Project Analysis
```
Lily, analyze the FE project. Show me:
1. Total issues
2. Issues by status (To Do, In Progress, Done)
3. Issues by priority
4. Recent trends (last 7 days)
```

**Expected**: Lily provides statistical analysis with percentages and insights.

---

### Test 2: Sprint Health Analysis
```
Lily, analyze today's issues in FE project. Provide:
1. How many issues were created today?
2. What's the priority distribution?
3. Are there any patterns in the labels?
4. Recommendations for the team
```

**Expected**: Data-driven insights with metrics.

---

### Test 3: Issue Deep-Dive
```
Lily, analyze issue FE-139 in detail. Tell me:
1. Full issue details
2. Related issues (if any)
3. Priority and labels significance
4. Recommendations for next steps
```

**Expected**: Comprehensive analysis of single issue.

---

## LILY FEATURE TEST - SECTION 2: Limited Write Operations

### Test 4: Subtask Creation (Lily's Primary Write)
```
Lily, create a subtask for FE-139:
- Summary: "Lily: Statistical analysis complete"
- Description: "Analytics validation for updated system prompt"
- Priority: Medium
- Labels: ["lily-analytics", "subtask-created", "validation"]
```

**Expected**:
- ✅ Lily creates subtask using JSON string for additional_fields
- ✅ Parent field correctly set to FE-139
- ✅ All fields applied from JSON string

---

### Test 5: Comment Addition
```
Lily, add an analytical comment to FE-140 summarizing the test results and status.
```

**Expected**: Lily adds professional, data-focused comment.

---

### Test 6: Worklog Entry
```
Lily, log 2 hours of analysis work on FE-139 with comment "System validation and analytics"
```

**Expected**: Worklog created successfully.

---

## LILY FEATURE TEST - SECTION 3: Permission Boundaries

### Test 7: Request Parent Issue Creation (Should Redirect)
```
Lily, create a new Bug in FE project for "Login error on production"
```

**Expected**:
- ❌ Lily should DECLINE and redirect to Tony
- ✅ Professional explanation of her limitations
- ✅ Offers alternative (create subtask, analyze existing issues, etc.)

**Correct Response Example**:
> "I have read-only access and cannot create parent-level issues (Tasks, Bugs, Stories, Epics). Please refer to Tony for this operation.
>
> However, I can help you by:
> 1. Analyzing existing bugs in the project
> 2. Creating subtasks under an existing bug
> 3. Providing recommendations on priority and labels
>
> Would you like me to analyze current bugs or create subtasks?"

---

### Test 8: Request Epic Creation (Should Redirect)
```
Lily, create an Epic for "User Authentication System"
```

**Expected**:
- ❌ Lily declines
- ✅ Redirects to Tony
- ✅ Offers analytical alternatives

---

## LILY FEATURE TEST - SECTION 4: Advanced Analytics

### Test 9: JQL Expertise
```
Lily, show me all high priority bugs created in the last 7 days in FE project
```

**Expected**:
- ✅ Lily constructs correct JQL
- ✅ Executes search
- ✅ Provides analysis of results

---

### Test 10: Multi-Step Analysis
```
Lily, I need a team productivity report:
1. How many issues were completed this week?
2. What's the average time to completion?
3. Who are the top contributors?
4. Any bottlenecks or blockers?
```

**Expected**:
- ✅ Multiple JQL queries
- ✅ Data aggregation
- ✅ Statistical analysis
- ✅ Actionable insights

---

## Expected Results Summary

### Tony (All Features)
| Feature | Expected | Status |
|---------|----------|--------|
| Create Task | ✅ FE-140 | Test |
| Update | ✅ Updated | Test |
| Comment | ✅ Added | Test |
| Worklog | ✅ 1h logged | Test |
| Subtask | ✅ FE-141 | Test |
| Batch Create | ✅ FE-142,143,144 | Test |
| Transition | ✅ To Done | Test |
| Version | ✅ v2.0-tony-test | Test |
| Link | ✅ Created | Test |

**Tony Result**: Should be 9/9 = 100% ✅

---

### Lily (Analytics + Limited Write)
| Feature | Expected | Status |
|---------|----------|--------|
| Project Analysis | ✅ Statistics | Test in n8n |
| Issue Analysis | ✅ Insights | Test in n8n |
| JQL Queries | ✅ Correct queries | Test in n8n |
| Subtask Create | ✅ With JSON string | Test in n8n |
| Add Comment | ✅ Professional | Test in n8n |
| Log Work | ✅ Time tracking | Test in n8n |
| Decline Parent Issue | ✅ Redirect to Tony | Test in n8n |
| Decline Epic | ✅ Redirect to Tony | Test in n8n |

**Lily Result**: Should validate role boundaries ✅

---

## Validation Checklist

After running all tests, verify:

### For Tony:
- [ ] All 9 features worked
- [ ] JSON strings parsed correctly
- [ ] Issue keys match API verification
- [ ] Links created properly
- [ ] Responses are helpful and clear
- [ ] Jira links provided in responses

### For Lily:
- [ ] Analytics are data-driven
- [ ] Subtask creation works with JSON strings
- [ ] Parent issues declined gracefully
- [ ] Redirects to Tony appropriately
- [ ] Professional communication style
- [ ] Metrics and percentages provided

---

## How to Test in n8n

1. **Open n8n** workflow with Tony and Lily
2. **Copy test prompts** from above
3. **Send to each agent** one by one
4. **Record results** in a spreadsheet or document
5. **Verify API** using curl commands if needed
6. **Report any failures** back for investigation

---

## API Verification Commands

**Check Lily's subtask** (if she creates one):
```bash
curl -s -u "dti_org@fpt.com:TOKEN" \
  "https://aifaads.atlassian.net/rest/api/3/issue/FE-XXX?fields=parent,summary,labels"
```

**Check comments**:
```bash
curl -s -u "dti_org@fpt.com:TOKEN" \
  "https://aifaads.atlassian.net/rest/api/3/issue/FE-XXX/comment"
```

**Check worklogs**:
```bash
curl -s -u "dti_org@fpt.com:TOKEN" \
  "https://aifaads.atlassian.net/rest/api/3/issue/FE-XXX/worklog"
```

---

**Execute these tests in n8n and report back the results!**
