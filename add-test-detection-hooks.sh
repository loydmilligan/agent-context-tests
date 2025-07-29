#!/bin/bash
# add-test-detection-hooks.sh
# Adds test detection capability to existing context tracking setup

set -e

echo "🔧 Adding test detection hooks to agent-context-tests..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f ".claude/settings.json" ] || [ ! -d ".claude/hooks" ]; then
    echo -e "${YELLOW}⚠️  Error: Not in the agent-context-tests directory${NC}"
    echo "Please run this from the root of agent-context-tests"
    exit 1
fi

# Create the test detection script
echo -e "${BLUE}📝 Creating test detection script...${NC}"
cat > .claude/hooks/detect-and-track-tests.sh << 'SCRIPT_EOF'
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
SCRIPT_EOF

# Make it executable
chmod +x .claude/hooks/detect-and-track-tests.sh

# Update the existing track-context-flow.sh to be test-aware
echo -e "${BLUE}📝 Enhancing context flow tracker for test awareness...${NC}"
cat > .claude/hooks/track-context-flow-enhanced.sh << 'SCRIPT_EOF'
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
SCRIPT_EOF

chmod +x .claude/hooks/track-context-flow-enhanced.sh

# Create test finalization script
echo -e "${BLUE}📝 Creating test finalization script...${NC}"
cat > .claude/hooks/finalize-test-results.sh << 'SCRIPT_EOF'
#!/bin/bash
# finalize-test-results.sh - Finalize and analyze test results

TEST_LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/test-results"
CURRENT_TEST_FILE="$TEST_LOG_DIR/current-test.json"

if [ -f "$TEST_LOG_DIR/.current-test-id" ]; then
    test_id=$(cat "$TEST_LOG_DIR/.current-test-id")
    
    # Add final metadata and analysis
    if [ -f "$CURRENT_TEST_FILE" ]; then
        final_log=$(jq --arg end_time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
            . + {
                timestamp_end: $end_time,
                duration_seconds: (($end_time | fromdate) - (.timestamp_start | fromdate)),
                summary: {
                    total_tools_used: (.tool_usage | length),
                    agents_involved: [.tool_usage[] | select(.tool == "Task") | .input_summary.subagent] | unique,
                    files_created: [.tool_usage[] | select(.tool == "Write") | .input_summary.file],
                    files_read: [.tool_usage[] | select(.tool == "Read") | .input_summary.file],
                    context_handoffs: (.context_flows | length)
                }
            }
        ' "$CURRENT_TEST_FILE")
        
        # Save with test ID
        echo "$final_log" | jq '.' > "$TEST_LOG_DIR/$test_id.json"
        
        # Append to master log
        echo "$final_log" >> "$TEST_LOG_DIR/all-tests.jsonl"
        
        # Log completion
        echo "{\"event\": \"test_completed\", \"test_id\": \"$test_id\", \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$TEST_LOG_DIR/../context-logs/context-flow.jsonl"
        
        echo "Test $test_id completed. Results saved to $TEST_LOG_DIR/$test_id.json"
    fi
    
    # Cleanup
    rm -f "$TEST_LOG_DIR/.current-test-id" "$CURRENT_TEST_FILE"
fi

exit 0
SCRIPT_EOF

chmod +x .claude/hooks/finalize-test-results.sh

# Backup existing settings.json
echo -e "${BLUE}📋 Backing up existing settings.json...${NC}"
cp .claude/settings.json .claude/settings.json.backup

# Update settings.json using jq to merge configurations
echo -e "${BLUE}⚙️  Updating Claude Code hooks configuration...${NC}"
# Read existing settings
existing_settings=$(cat .claude/settings.json)

# Create the new hook configuration to add
new_hook_config=$(cat <<'EOF'
{
  "UserPromptSubmit": [{
    "hooks": [{
      "type": "command",
      "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/detect-and-track-tests.sh"
    }]
  }]
}
EOF
)

# Merge configurations
echo "$existing_settings" | jq --argjson new "$new_hook_config" '
  .hooks.UserPromptSubmit = $new.UserPromptSubmit |
  # Update PostToolUse to use enhanced tracker
  .hooks.PostToolUse[0].hooks[0].command = "$CLAUDE_PROJECT_DIR/.claude/hooks/track-context-flow-enhanced.sh" |
  # Add test finalization to Stop hook
  .hooks.Stop[0].hooks += [{
    "type": "command",
    "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/finalize-test-results.sh",
    "timeout": 5
  }]
' > .claude/settings.json.tmp

# Validate JSON before replacing
if jq empty .claude/settings.json.tmp 2>/dev/null; then
    mv .claude/settings.json.tmp .claude/settings.json
    echo -e "${GREEN}✅ Settings updated successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Error updating settings.json - backup preserved${NC}"
    rm .claude/settings.json.tmp
    exit 1
fi

# Create test analysis script
echo -e "${BLUE}📊 Creating enhanced test analysis script...${NC}"
cat > analyze-test-results.sh << 'SCRIPT_EOF'
#!/bin/bash
# analyze-test-results.sh - Analyze test detection and results

echo "🧪 Test Results Analysis"
echo "======================="

TEST_DIR=".claude/test-results"

if [ -d "$TEST_DIR" ]; then
    # Count test files
    test_count=$(ls -1 "$TEST_DIR"/test-*.json 2>/dev/null | wc -l)
    echo -e "\n📋 Total tests recorded: $test_count"
    
    if [ $test_count -gt 0 ]; then
        echo -e "\n🔍 Recent tests:"
        for test_file in $(ls -1t "$TEST_DIR"/test-*.json 2>/dev/null | head -5); do
            if [ -f "$test_file" ]; then
                test_id=$(basename "$test_file" .json)
                test_desc=$(jq -r '.test_description // .user_prompt' "$test_file" | head -n 1)
                duration=$(jq -r '.duration_seconds // "N/A"' "$test_file")
                agents=$(jq -r '.summary.agents_involved | join(", ")' "$test_file" 2>/dev/null || echo "N/A")
                
                echo -e "\n  📄 $test_id"
                echo "     Description: $test_desc"
                echo "     Duration: ${duration}s"
                echo "     Agents: $agents"
            fi
        done
    fi
    
    # Aggregate statistics
    if [ -f "$TEST_DIR/all-tests.jsonl" ]; then
        echo -e "\n📊 Aggregate Statistics:"
        
        # Most tested agents
        echo -e "\n  Most tested agents:"
        jq -r '.summary.agents_involved[]' "$TEST_DIR"/test-*.json 2>/dev/null | \
            sort | uniq -c | sort -nr | head -5 | \
            while read count agent; do
                echo "    - $agent: $count tests"
            done
        
        # Average test duration
        avg_duration=$(jq -s 'map(.duration_seconds // 0) | add / length' "$TEST_DIR"/test-*.json 2>/dev/null || echo "N/A")
        echo -e "\n  Average test duration: ${avg_duration}s"
    fi
fi

# Check context logs
if [ -f ".claude/context-logs/context-flow.jsonl" ]; then
    test_events=$(grep '"event": "test_' .claude/context-logs/context-flow.jsonl | wc -l)
    echo -e "\n📈 Test events tracked: $test_events"
fi

echo -e "\n💡 Run specific test analysis:"
echo "   jq '.' .claude/test-results/test-YYYYMMDD-HHMMSS-XXXXXX.json"
SCRIPT_EOF

chmod +x analyze-test-results.sh

# Final summary
echo
echo -e "${GREEN}✅ Test detection hooks added successfully!${NC}"
echo
echo "🎯 What's new:"
echo "   - Automatic test detection from user prompts"
echo "   - Enhanced context tracking for tests"
echo "   - Test result finalization and analysis"
echo "   - Comprehensive test metrics"
echo
echo "📝 How to use:"
echo "1. Restart Claude Code to activate new hooks"
echo
echo "2. Start any test with phrases like:"
echo "   - 'Test the context handoff...'"
echo "   - 'Run a test of parallel execution...'"
echo "   - 'Testing if agents can...'"
echo
echo "3. Tests will be automatically:"
echo "   - Detected and tracked"
echo "   - Logged with all operations"
echo "   - Finalized with summaries"
echo "   - Auto-committed to git"
echo
echo "4. Analyze results with:"
echo "   ./analyze-test-results.sh"
echo
echo -e "${YELLOW}💡 Note: Original settings backed up to settings.json.backup${NC}"
