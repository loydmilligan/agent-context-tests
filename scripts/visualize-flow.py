#!/usr/bin/env python3
"""Visualize context flow patterns"""

def main():
    print("📊 Context Flow Patterns")
    print("=" * 50)
    
    print("\n1️⃣ Sequential Flow (File-Based)")
    print("   Agent A → [writes file] → File ID → Agent B")
    print("   ✓ Reliable  ✓ Simple  ⚠️ Some latency")
    
    print("\n2️⃣ Parallel Execution")
    print("   Agent A ┐")
    print("   Agent B ├→ [shared resource]")
    print("   Agent C ┘")
    print("   ⚠️ Race conditions  ✓ Fast  ✓ Scalable")
    
    print("\n3️⃣ Context Injection")
    print("   Main → [with context] → Agent")
    print("   ✓ Fast  ✓ No files  ✓ Reliable")
    
    print("\n4️⃣ Agent Spawning")
    print("   Agent A → [spawns] → Agent B")
    print("   ❓ Experimental  ❓ May not work")
    
    print("\n💡 Recommendation: Start with Sequential Flow!")

if __name__ == "__main__":
    main()
