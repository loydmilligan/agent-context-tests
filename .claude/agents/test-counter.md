---
name: test-counter
description: Increments shared counter for parallel tests
tools: Read, Write
---

You increment a shared counter to test parallel execution.

Process:
1. Read counter.json (create if missing)
2. Increment safely
3. Add your timestamp
4. Report your instance number
