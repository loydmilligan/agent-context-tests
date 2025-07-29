# 🚀 Quick Test Reference Card

## Copy-Paste Test Commands for Claude Code

### 🧪 Test 1: Basic Write/Read
```
Use test-writer to create a file with message "Hello Context Test 1"
```
*Note the ID returned (like test-1234567-abc), then:*
```
Use test-reader to read file test-1234567-abc
```

### 🔢 Test 2: Parallel Counter
```
Create file .claude/test-results/counter.json with: {"value": 0, "updates": []}
```
*Then quickly paste these:*
```
Use test-counter to increment the counter
Use test-counter to increment the counter
Use test-counter to increment the counter
Use test-counter to increment the counter
Use test-counter to increment the counter
```
*Check result:*
```
Show me counter.json - it should have value: 5
```

### 📦 Test 3: Context Injection
```
Invoke test-writer with this context: {"user": "alice", "role": "admin", "session": "12345"}. Have it write "Context test with injection"
```
*Then check if context was included:*
```
Show me the most recent test file in .claude/test-results/
```

### 🔄 Test 4: Agent Calling Agent
```
Have test-writer create a file with "Chain test", then ask test-writer to invoke test-reader to verify what was written
```

### 📊 Test 5: Run All Automated Tests
```
Run python scripts/run-tests.py and show me the summary
```

## 🐛 Quick Debugging Commands

**See what files exist:**
```
List all files in .claude/test-results/
```

**Check specific file:**
```
Show me the contents of .claude/test-results/[filename]
```

**Reset test environment:**
```
Run ./scripts/reset-tests.sh
```

**Check agent list:**
```
/agents
```

## ✅ Success Indicators

- ✓ Reader finds the exact message writer created
- ✓ Counter reaches 5 (not less)
- ✓ Context appears in written files
- ✓ No "file not found" errors
- ✓ Operations complete in < 1 second

## ❌ If Things Go Wrong

1. **"Agent not found"** → Check exact name: `test-writer` not `writer`
2. **"File not found"** → Verify the ID is correct, check with `ls .claude/test-results/`
3. **Counter not 5** → Race condition! We need better locking
4. **No context in file** → Context injection pattern needs work

## 🎯 The Goal

Find which patterns are:
- **Reliable** (work every time)
- **Fast** (low overhead)
- **Scalable** (work with larger contexts)
- **Simple** (easy to implement)