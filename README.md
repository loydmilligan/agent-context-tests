# Agent Context Sharing Test Framework

A comprehensive testing framework for understanding how Claude Code agents can share context and work together effectively.

## Overview

This repository contains minimal test agents and automated tests to explore different patterns for context sharing between Claude Code agents. The goal is to identify reliable, efficient patterns for multi-agent workflows.

## Repository Structure

```
agent-context-tests/
├── .claude/
│   ├── agents/          # Test agents
│   ├── commands/        # Test commands
│   └── test-results/    # Test outputs
├── tests/               # Test scenarios
├── scripts/             # Test automation
├── docs/                # Additional documentation
├── CLAUDE.md           # AI rules for this project
└── README.md           # This file
```

## Quick Start

```bash
# 1. Setup (you've already done this!)
./setup-context-tests.sh

# 2. Start Claude Code in this directory
cd agent-context-tests
claude

# 3. Run manual tests (see Test Patterns below)
# 4. Run automated tests
python scripts/run-tests.py

# 5. Analyze results
python scripts/visualize-flow.py
```

## Test Patterns

### 1. Sequential Handoff
- **Goal**: Test basic A→B context passing
- **Method**: Agent writes file, returns ID, another agent reads
- **Command**: `Use test-writer to create a file with "Test message"`
- **Measure**: Success rate, timing, data integrity

### 2. Parallel Execution  
- **Goal**: Test multiple agents running simultaneously
- **Method**: Multiple agents increment shared counter
- **Command**: Invoke test-counter multiple times rapidly
- **Measure**: Final count accuracy, race conditions

### 3. Context Injection
- **Goal**: Test main agent pre-loading context
- **Method**: Main agent provides context in agent invocation
- **Command**: Include context object when invoking agent
- **Measure**: Context availability, overhead

### 4. File-Based Communication
- **Goal**: Test bidirectional agent communication
- **Method**: Agents read/write request/response files
- **Command**: Agent A writes request, Agent B writes response
- **Measure**: Round-trip success, timing

### 5. Agent Spawning
- **Goal**: Test agents invoking other agents
- **Method**: Agent A invokes Agent B with context
- **Command**: Tell agent to invoke another agent
- **Measure**: Success rate, context passing

## Test Agents

### test-writer
- Writes timestamped test data files
- Returns file IDs for handoff
- Records any context received

### test-reader
- Reads files by ID
- Verifies data integrity
- Reports timing information

### test-counter
- Increments shared counter
- Tests parallel execution
- Records instance information

## Key Metrics

1. **Reliability**: % of successful context transfers
2. **Performance**: Average handoff time (ms)
3. **Concurrency**: Can agents truly run in parallel?
4. **Data Integrity**: Is context preserved exactly?
5. **Scalability**: Performance with larger contexts

## Manual Test Examples

```bash
# Test 1: Basic handoff
Use test-writer to create a file with message "Hello Test"
# Note returned ID
Use test-reader to read file [ID]

# Test 2: Parallel execution
Create counter.json with {"value": 0, "updates": []}
Use test-counter to increment (repeat 5x quickly)
Check final count in counter.json

# Test 3: Context injection
Invoke test-writer with this context: {"user": "test", "session": "123"}
Verify context appears in written file
```

## Automated Testing

The `scripts/run-tests.py` script runs all patterns automatically and generates:
- Timing metrics
- Success rates  
- Performance analysis
- Summary report in `.claude/test-results/test-summary.json`

## Results Analysis

After testing, check:
1. **test-summary.json** - Aggregated results
2. **Individual test files** - Detailed context data
3. **Visualization** - Run `visualize-flow.py` for patterns

## Known Limitations

- Agents cannot directly communicate (need main agent or files)
- File I/O adds latency to context sharing
- Token limits may affect large context transfers
- Parallel execution may have race conditions

## Contributing

To add new test patterns:
1. Create new test agent in `.claude/agents/`
2. Add test scenario in `tests/`
3. Update automation in `scripts/`
4. Document findings

## Next Steps

Based on test results, we'll:
1. Choose optimal patterns for production workflows
2. Build helper utilities for context management
3. Create best practices documentation
4. Design context-librarian architecture
