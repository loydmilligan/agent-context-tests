# Test: Simple Sequential Context

## Goal
Verify basic context passing from Agent A to Agent B

## Steps
1. Main agent invokes test-writer with "Hello, World!"
2. Writer creates file and returns ID
3. Main agent invokes test-reader with the ID
4. Reader confirms data received

## Expected Result
- Reader reports finding "Hello, World!"
- No data corruption
- Reasonable timing (<1 second)

## How to Run
```
Use test-writer to write "Hello, World!"
Then use test-reader with the returned ID
```
