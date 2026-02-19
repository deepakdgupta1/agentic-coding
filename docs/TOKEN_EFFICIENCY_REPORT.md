# Token Efficiency of ACFS Agent Tools

This report evaluates the token efficiency and context management strategies of the ACFS (Agentic Coding Flywheel Setup) toolchain.

## Executive Summary

The ACFS architecture utilizes a **defense-in-depth strategy for token efficiency**:

1.  **Offload**: Move state and reasoning out of the context window (Agents, Beads).
2.  **Retrieve**: Fetch only what is needed, when it is needed (CASS, Meta Skill).
3.  **Compress**: Optimize the format of data injected into the context (Toon, S2P, MDWB).
4.  **Refine**: Iterate on plans cheaply before committing to expensive code generation (APR, Brenner).

## 1. Offload: "Offline Compute, Online Context"

| Tool                           | Strategy          | Efficiency Impact      | Mechanism                                                                                                                                |
| ------------------------------ | ----------------- | ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| **MCP Agent Mail**             | Archival Storage  | ⭐⭐⭐⭐⭐ (Very High) | Messages stored in SQLite, not session history. Agents pull specific threads/inbox items on demand.                                      |
| **Beads (br/bv)**              | Graph Triage      | ⭐⭐⭐⭐⭐ (Very High) | `bv` computes PageRank/critical paths locally. LLM receives a <500 token JSON summary instead of 100+ raw issues.                        |
| **Repo Updater (ru)**          | Automated Commits | ⭐⭐⭐⭐ (High)        | `ru agent-sweep` handles commit generation and message writing, offloading this repetitive "housekeeping" from the main agent's context. |
| **Coding Agent Usage Tracker** | Visibility        | ⭐⭐⭐ (Indirect)      | `caut` provides visibility into token usage, allowing developers to identify and optimize inefficient workflows.                         |

## 2. Retrieve: "Just-in-Time Knowledge"

| Tool                 | Strategy           | Efficiency Impact      | Mechanism                                                                                                                     |
| -------------------- | ------------------ | ---------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **CASS**             | Semantic Search    | ⭐⭐⭐⭐ (High)        | Indexes past sessions. Agents search/retrieve specific snippets (`--limit N`) rather than loading full logs.                  |
| **Meta Skill (ms)**  | Hybrid RAG         | ⭐⭐⭐⭐⭐ (Very High) | Manages skills/docs via RAG. Uses Thompson sampling to surface the most effective tools/docs, keeping the system prompt lean. |
| **Cass Memory (cm)** | Procedural Memory  | ⭐⭐⭐⭐⭐ (Very High) | Distills lessons into rules. Injects only ~5 relevant rules per task, preventing repetitive debugging loops.                  |
| **Brenner Bot**      | Research Synthesis | ⭐⭐⭐⭐⭐ (Very High) | Manages a "Primary Source Corpus" of citations. Agents query this corpus rather than holding entire papers in context.        |

## 3. Compress: "High-Density Context"

| Tool                       | Strategy            | Efficiency Impact | Mechanism                                                                                                                  |
| -------------------------- | ------------------- | ----------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **Toon Rust (tru)**        | Token Optimization  | ⭐⭐⭐ (Medium)   | Converts specialized data structures into "Token-Optimized Notation" (TON), reducing token count compared to raw JSON/XML. |
| **Source to Prompt (s2p)** | Context Packing     | ⭐⭐⭐⭐ (High)   | selecting/packing code files with real-time token counting, ensuring "budget-aware" context construction.                  |
| **Markdown Web Browser**   | Content Reduction   | ⭐⭐⭐⭐ (High)   | Converts heavy HTML/JS websites into clean, token-efficient Markdown, stripping ads/boilerplate.                           |
| **JeffreysPrompts (jfp)**  | Prompt Optimization | ⭐⭐⭐⭐ (High)   | Provides "battle-tested" prompts that are optimized for specific models, reducing trial-and-error token waste.             |

## Conclusion

ACFS treats the **Context Window as a Scarcity**. By combining offline storage (SQLite), local compute (Graph algorithms, RAG), and optimized formats (Markdown/TON), it enables agents to tackle complex, long-running projects that would otherwise be impossible or prohibitively expensive.
