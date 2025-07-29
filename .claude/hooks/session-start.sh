#!/bin/bash
# session-start.sh - Initialize context tracking for new session

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_LOG=".claude/context-logs/sessions.log"

mkdir -p .claude/context-logs

echo "=== New Context Testing Session Started ===" >> "$SESSION_LOG"
echo "Timestamp: $TIMESTAMP" >> "$SESSION_LOG"
echo "Working Directory: $(pwd)" >> "$SESSION_LOG"
echo "" >> "$SESSION_LOG"

# Create session marker
echo "Context testing session initialized at $TIMESTAMP" > .claude/test-results/session-marker.txt

exit 0
