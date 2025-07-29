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
