#!/bin/bash
# analyze-context-flow.sh - Analyze captured context flow data

echo "📊 Context Flow Analysis"
echo "======================="

if [ -f .claude/context-logs/context-flow.jsonl ]; then
    echo -e "\n📋 Total events logged: $(wc -l < .claude/context-logs/context-flow.jsonl)"
    
    echo -e "\n🔧 Tool usage breakdown:"
    jq -r '.tool_name // "unknown"' .claude/context-logs/context-flow.jsonl | sort | uniq -c | sort -nr
fi

if [ -f .claude/context-logs/agent-invocations.log ]; then
    echo -e "\n🤖 Agent invocations: $(grep -c "Agent invoked:" .claude/context-logs/agent-invocations.log)"
fi

if [ -f .claude/context-logs/file-operations.log ]; then
    echo -e "\n📁 File operations: $(wc -l < .claude/context-logs/file-operations.log)"
    echo "Recent operations:"
    tail -n 10 .claude/context-logs/file-operations.log
fi

echo -e "\n📝 Git commits created:"
git log --oneline --grep="Auto-commit: Agent test completed" 2>/dev/null | head -n 10
