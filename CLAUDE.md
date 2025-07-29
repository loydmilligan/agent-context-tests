# AI Rules for Agent Context Testing

## Project Context

You are helping test and understand context sharing patterns between Claude Code agents. This is a testing/research project to determine the best patterns for multi-agent workflows.

## Primary Objectives

1. **Test Reliability** - Ensure context sharing patterns work consistently
2. **Measure Performance** - Track timing and overhead of different patterns  
3. **Identify Limitations** - Document what doesn't work and why
4. **Find Best Practices** - Determine optimal patterns for production use

## When Working in This Project

### Always:
- Be explicit about which agent you're invoking
- Note any errors or unexpected behavior
- Track timing when relevant
- Preserve test data for analysis

### Test Scenarios Should:
- Start simple and increase complexity
- Test both success and failure cases
- Measure quantifiable metrics
- Be reproducible

### When Invoking Test Agents:
- Use exact agent names (test-writer, test-reader, test-counter)
- Provide clear, specific instructions
- Note returned IDs or values
- Verify expected outcomes

## Key Patterns We're Testing

1. **File-Based Handoff**: Agent A writes → returns ID → Agent B reads
2. **Context Injection**: Main agent provides context when invoking
3. **Parallel Execution**: Multiple agents accessing shared resources
4. **Agent Spawning**: Agent invoking another agent
5. **Bidirectional Comm**: Request/response between agents

## Important Measurements

- **Success Rate**: Did context transfer work?
- **Timing**: How long did operations take?
- **Data Integrity**: Was context preserved exactly?
- **Concurrency**: Did parallel operations work correctly?

## Debugging Context Issues

When context sharing fails:
1. Check if file was created: `ls .claude/test-results/`
2. Verify file contents: `cat .claude/test-results/[file]`
3. Ensure agents have correct tools/permissions
4. Check for race conditions in parallel tests
5. Verify agent names are exact

## Test Data Standards

All test data should include:
- Unique ID with timestamp
- Source agent identification  
- Creation timestamp
- Any received context
- Clear success/failure indicators

## Remember

This is an experimental project to understand Claude Code's capabilities. Document everything - successes, failures, and surprises. The goal is to build reliable multi-agent workflows based on what we learn here.
