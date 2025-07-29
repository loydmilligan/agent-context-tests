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
