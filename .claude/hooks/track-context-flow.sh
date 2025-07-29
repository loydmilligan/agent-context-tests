#!/bin/bash
# track-context-flow.sh - Log context flow events for analysis

# Parse the JSON input from stdin
INPUT=$(cat)

# Extract key information
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')

# Create context log directory if it doesn't exist
mkdir -p .claude/context-logs

# Log full event to JSONL file
CONTEXT_LOG=".claude/context-logs/context-flow.jsonl"
echo "$INPUT" | jq -c ". + {logged_at: \"$TIMESTAMP\", hook_event: \"$HOOK_EVENT\"}" >> "$CONTEXT_LOG"

# If this was a Task (subagent invocation), track it specially
if [ "$TOOL_NAME" = "Task" ]; then
    AGENT_NAME=$(echo "$INPUT" | jq -r '.tool_input.agent // .tool_input.agent_name // "unknown"')
    TASK_DESC=$(echo "$INPUT" | jq -r '.tool_input.task // .tool_input.description // "no description"' | head -n 1)
    
    AGENT_LOG=".claude/context-logs/agent-invocations.log"
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S")] Agent invoked: $AGENT_NAME" >> "$AGENT_LOG"
    echo "  Task: $TASK_DESC" >> "$AGENT_LOG"
    echo "  Session: $SESSION_ID" >> "$AGENT_LOG"
    echo "" >> "$AGENT_LOG"
fi

# Log file operations for context passing analysis
if [[ "$TOOL_NAME" =~ ^(Read|Write|Edit)$ ]]; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // "unknown"')
    FILE_OPS_LOG=".claude/context-logs/file-operations.log"
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S")] $TOOL_NAME: $FILE_PATH (Session: $SESSION_ID)" >> "$FILE_OPS_LOG"
fi

# Always exit successfully to not block Claude Code
exit 0
