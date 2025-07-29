#!/bin/bash
# detect-and-track-tests.sh - Detect test requests and initialize tracking

TEST_LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/test-results"
mkdir -p "$TEST_LOG_DIR"

# Read the JSON input
json_input=$(cat)
prompt=$(echo "$json_input" | jq -r '.prompt')

# Check if this is a test request
if echo "$prompt" | grep -iE '(^test |^run a test|^testing |test the |test if |^run test)'; then
    # It's a test! Initialize tracking
    test_id="test-$(date +%Y%m%d-%H%M%S)-$(openssl rand -hex 3)"
    
    # Extract test description from prompt
    test_description=$(echo "$prompt" | sed -E 's/^(test|run a test|testing|run test) //i')
    
    # Initialize test log
    cat <<EOF > "$TEST_LOG_DIR/current-test.json"
{
    "test_id": "$test_id",
    "timestamp_start": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "user_prompt": "$prompt",
    "test_description": "$test_description",
    "test_detected": true,
    "tool_usage": [],
    "agent_outputs": {},
    "context_flows": []
}
EOF
    
    # Store test ID for other hooks
    echo "$test_id" > "$TEST_LOG_DIR/.current-test-id"
    
    # Log to context flow
    echo "{\"event\": \"test_started\", \"test_id\": \"$test_id\", \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$TEST_LOG_DIR/../context-logs/context-flow.jsonl"
    
    # Add context to tell Claude this is a test
    output_json=$(cat <<EOF
{
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "TEST MODE ACTIVATED: Test ID $test_id. All agent invocations and tool usage will be tracked for analysis. The test will be automatically logged and committed."
    }
}
EOF
)
    echo "$output_json"
fi

# Always allow the prompt to proceed
exit 0
