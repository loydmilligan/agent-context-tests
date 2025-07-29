#!/bin/bash
# track-context-flow-enhanced.sh - Enhanced version with test tracking

# Parse the JSON input from stdin
INPUT=$(cat)

# Extract key information
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')

# Create context log directory if it doesn't exist
mkdir -p .claude/context-logs

# Check if we're in test mode
TEST_LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/test-results"
CURRENT_TEST_FILE="$TEST_LOG_DIR/current-test.json"
IN_TEST_MODE=false
if [ -f "$TEST_LOG_DIR/.current-test-id" ]; then
    IN_TEST_MODE=true
    TEST_ID=$(cat "$TEST_LOG_DIR/.current-test-id")
fi

# Log full event to JSONL file
CONTEXT_LOG=".claude/context-logs/context-flow.jsonl"
echo "$INPUT" | jq -c ". + {logged_at: \"$TIMESTAMP\", hook_event: \"$HOOK_EVENT\", in_test_mode: $IN_TEST_MODE, test_id: \"${TEST_ID:-none}\"}" >> "$CONTEXT_LOG"

# If this was a Task (subagent invocation), track it specially
if [ "$TOOL_NAME" = "Task" ]; then
    AGENT_NAME=$(echo "$INPUT" | jq -r '.tool_input.agent // .tool_input.agent_name // "unknown"')
    TASK_DESC=$(echo "$INPUT" | jq -r '.tool_input.task // .tool_input.description // "no description"' | head -n 1)
    
    AGENT_LOG=".claude/context-logs/agent-invocations.log"
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S")] Agent invoked: $AGENT_NAME" >> "$AGENT_LOG"
    echo "  Task: $TASK_DESC" >> "$AGENT_LOG"
    echo "  Session: $SESSION_ID" >> "$AGENT_LOG"
    if [ "$IN_TEST_MODE" = true ]; then
        echo "  Test ID: $TEST_ID" >> "$AGENT_LOG"
    fi
    echo "" >> "$AGENT_LOG"
    
    # If in test mode, track context flows
    if [ "$IN_TEST_MODE" = true ] && [ -f "$CURRENT_TEST_FILE" ]; then
        context_flow=$(echo "$INPUT" | jq '{
            timestamp: now | strftime("%Y-%m-%dT%H:%M:%SZ"),
            from: "main",
            to: .tool_input.agent_name,
            method: "task_invocation",
            data_transferred: .tool_input.prompt,
            tool_response: null
        }')
        
        # Add to context flows in test file
        jq --argjson flow "$context_flow" '.context_flows += [$flow]' "$CURRENT_TEST_FILE" > "$CURRENT_TEST_FILE.tmp"
        mv "$CURRENT_TEST_FILE.tmp" "$CURRENT_TEST_FILE"
    fi
fi

# Log file operations for context passing analysis
if [[ "$TOOL_NAME" =~ ^(Read|Write|Edit)$ ]]; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // "unknown"')
    FILE_OPS_LOG=".claude/context-logs/file-operations.log"
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S")] $TOOL_NAME: $FILE_PATH (Session: $SESSION_ID)" >> "$FILE_OPS_LOG"
    if [ "$IN_TEST_MODE" = true ]; then
        echo "  Test ID: $TEST_ID" >> "$FILE_OPS_LOG"
    fi
fi

# If in test mode, track all tool usage
if [ "$IN_TEST_MODE" = true ] && [ -f "$CURRENT_TEST_FILE" ]; then
    tool_info=$(echo "$INPUT" | jq '{
        timestamp: now | strftime("%Y-%m-%dT%H:%M:%SZ"),
        tool: .tool_name,
        agent: .agent_name // "main",
        input_summary: (
            if .tool_name == "Task" then
                {
                    subagent: .tool_input.agent_name,
                    prompt_preview: (.tool_input.prompt | .[0:100]),
                    context_method: "task_invocation"
                }
            elif .tool_name == "Write" then
                {file: .tool_input.file_path, content_length: (.tool_input.content | length)}
            elif .tool_name == "Read" then
                {file: .tool_input.file_path}
            else
                .tool_input
            end
        )
    }')
    
    # Append to test log
    jq --argjson tool "$tool_info" '.tool_usage += [$tool]' "$CURRENT_TEST_FILE" > "$CURRENT_TEST_FILE.tmp"
    mv "$CURRENT_TEST_FILE.tmp" "$CURRENT_TEST_FILE"
fi

# Always exit successfully to not block Claude Code
exit 0
