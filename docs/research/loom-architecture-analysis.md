# Loom Architecture Deep Analysis

> A comprehensive analysis of the Loom AI coding agent system for use by AI agents building multi-agent autonomous coding systems.

## Executive Summary

Loom is a production-grade AI coding agent built in Rust with 59+ crates organized as a Cargo workspace. It provides a REPL interface, web UI, and IDE integrations (VS Code) for LLM-powered development tasks. The architecture emphasizes **modularity**, **extensibility**, **security**, and **reliability** through trait-based abstractions, a deterministic state machine, and robust error handling.

**Key Differentiators:**
- Server-side LLM proxy (API keys never leave server)
- Deterministic agent state machine with 7 states
- Ephemeral Kubernetes-based remote execution (Weaver)
- Multi-provider LLM support with unified abstraction
- Offline-first thread persistence with optional sync
- Full ABAC authorization system
- Agent Client Protocol (ACP) for IDE integration

---

## 1. High-Level Architecture

### 1.1 System Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐ │
│  │ loom-cli │  │ loom-web │  │ loom-acp │  │ loom-vscode      │ │
│  │  (REPL)  │  │ (Svelte) │  │(JSON-RPC)│  │ (VS Code Ext)    │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────────┬─────────┘ │
└───────┼─────────────┼─────────────┼─────────────────┼───────────┘
        │             │             │                 │
        ▼             ▼             ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                         SERVER LAYER                             │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                      loom-server                             ││
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐  ││
│  │  │ LLM Proxy   │  │ Thread API   │  │ Weaver Provisioner │  ││
│  │  │ /proxy/*    │  │ /v1/threads  │  │ /api/weaver        │  ││
│  │  └──────┬──────┘  └──────────────┘  └────────────────────┘  ││
│  └─────────┼────────────────────────────────────────────────────┘│
└────────────┼────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                       PROVIDER LAYER                             │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────────┐ │
│  │loom-llm-       │  │loom-llm-       │  │loom-llm-           │ │
│  │anthropic       │  │openai          │  │vertex              │ │
│  └────────────────┘  └────────────────┘  └────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Crate Organization (59 Crates)

| Category | Crates | Purpose |
|----------|--------|---------|
| **Core** | `loom-core` | State machine, abstractions, message types |
| **CLI** | `loom-cli`, `loom-cli-*` (8 crates) | REPL, config, credentials, tools, git, spool |
| **Server** | `loom-server`, `loom-server-*` (5 crates) | HTTP API, database, sessions, config |
| **LLM** | `loom-llm-*` (6 crates) | Anthropic, OpenAI, Vertex, proxy, service |
| **Auth** | `loom-auth-*` (6 crates) | OAuth (GitHub, Google, Okta), magic link, device code |
| **Tools** | `loom-tools` | Tool registry and implementations |
| **Thread** | `loom-thread` | Conversation persistence |
| **Weaver** | `loom-weaver`, `loom-k8s`, `loom-weaver-*` | K8s pod provisioning, secrets, WireGuard |
| **Infrastructure** | `loom-http`, `loom-i18n`, `loom-secret`, `loom-analytics-*` | HTTP, i18n, secrets, analytics |
| **Feature Flags** | `loom-feature-flags-*` | Runtime feature toggles |
| **IDE** | `loom-acp` | Agent Client Protocol for editors |

---

## 2. Agent State Machine

The heart of Loom is a **deterministic, synchronous state machine** that governs all agent behavior. This design enables predictable, testable transitions and clean separation between state logic and I/O.

### 2.1 States (7 Total)

```rust
enum AgentState {
    WaitingForUserInput { conversation: ConversationContext },
    CallingLlm { conversation, retries: u32 },
    ProcessingLlmResponse { conversation, response: LlmResponse },
    ExecutingTools { conversation, executions: Vec<ToolExecutionStatus> },
    PostToolsHook { conversation, pending_llm_request, completed_tools },
    Error { conversation, error, retries, origin: ErrorOrigin },
    ShuttingDown,
}
```

### 2.2 Events (7 Types)

```rust
enum AgentEvent {
    UserInput(String),
    LlmEvent(LlmEvent),           // TextDelta, ToolCallDelta, Completed, Error
    ToolProgress(ToolProgress),
    ToolCompleted(ToolResult),
    PostToolsHookCompleted,
    RetryTimeoutFired,
    ShutdownRequested,
}
```

### 2.3 Actions (7 Types)

Actions are returned by the state machine and executed by the caller (CLI/server):

```rust
enum AgentAction {
    SendLlmRequest(LlmRequest),
    ExecuteTools(Vec<ToolCall>),
    RunPostToolsHook(Vec<CompletedTool>),
    WaitForInput,
    DisplayMessage(String),
    DisplayError(String),
    Shutdown,
}
```

### 2.4 State Transition Diagram

```
                    UserInput
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                  WaitingForUserInput                         │
└─────────────────────────────────────────────────────────────┘
                        │
                        ▼ SendLlmRequest
┌─────────────────────────────────────────────────────────────┐
│                      CallingLlm                              │
│                   (retries: u32)                             │
└─────────────────────────────────────────────────────────────┘
          │                              │
          │ LlmEvent::Completed          │ LlmEvent::Error
          ▼                              ▼
┌───────────────────────┐      ┌─────────────────────────────┐
│ ProcessingLlmResponse │      │          Error              │
└───────────────────────┘      │  (retries < max_retries)    │
          │                    └─────────────────────────────┘
          │                              │
          ├─── No tools ───────────────► │ RetryTimeoutFired
          │                              │
          │                              ▼
          │                    ┌─────────────────────────────┐
          │                    │       CallingLlm            │
          │                    │    (retries incremented)    │
          ▼                    └─────────────────────────────┘
┌───────────────────────┐
│    ExecutingTools     │◄──────────────────────────────────┐
│ (parallel execution)  │                                    │
└───────────────────────┘                                    │
          │                                                  │
          │ All tools completed                              │
          ▼                                                  │
┌───────────────────────┐                                    │
│    PostToolsHook      │──── (if mutating tools) ──────────►│
│ (auto-commit, etc.)   │                                    │
└───────────────────────┘                                    │
          │                                                  │
          │ PostToolsHookCompleted                           │
          ▼                                                  │
    CallingLlm ◄─────────────────────────────────────────────┘
    (loop continues until no more tool calls)

                    ShutdownRequested (from any state)
                              │
                              ▼
                    ┌─────────────────┐
                    │  ShuttingDown   │
                    └─────────────────┘
```

### 2.5 Design Benefits

| Benefit | Description |
|---------|-------------|
| **Testability** | Pure state transitions can be unit tested without I/O |
| **Predictability** | Deterministic behavior, no hidden state |
| **Debuggability** | State + event + action logging provides full trace |
| **Extensibility** | New states/events added without breaking existing logic |
| **Error Recovery** | Explicit error state with retry logic |

---

## 3. LLM Client Abstraction

### 3.1 Unified Interface

```rust
#[async_trait]
pub trait LlmClient: Send + Sync {
    async fn complete(&self, request: LlmRequest) -> Result<LlmResponse, LlmError>;
    async fn complete_streaming(&self, request: LlmRequest) -> Result<LlmStream, LlmError>;
}
```

### 3.2 Request/Response Types

```rust
struct LlmRequest {
    model: String,
    messages: Vec<Message>,
    tools: Vec<ToolDefinition>,
    max_tokens: Option<u32>,
    temperature: Option<f32>,
}

struct LlmResponse {
    message: Message,
    tool_calls: Vec<ToolCall>,
    usage: Option<Usage>,
    finish_reason: Option<String>,
}

struct Message {
    role: Role,  // System, User, Assistant, Tool
    content: String,
    tool_call_id: Option<String>,
    name: Option<String>,
}
```

### 3.3 Streaming Architecture

```rust
enum LlmEvent {
    TextDelta { content: String },
    ToolCallDelta { call_id, tool_name, arguments_fragment },
    Completed(LlmResponse),
    Error(LlmError),
}

struct LlmStream {
    inner: Pin<Box<dyn Stream<Item = LlmEvent> + Send>>,
}
```

### 3.4 Server-Side Proxy Architecture

**Security Model:** API keys stored exclusively server-side, never in client binaries.

```
┌─────────────┐     HTTP/SSE      ┌─────────────┐     Provider API    ┌─────────────┐
│   Client    │ ────────────────► │   Server    │ ──────────────────► │  Anthropic  │
│ (loom-cli)  │                   │ LlmService  │                     │   OpenAI    │
│             │ ◄──────────────── │             │ ◄────────────────── │   Vertex    │
└─────────────┘                   └─────────────┘                     └─────────────┘
                                        │
                                        │ API keys stored here only
                                        ▼
                              ┌─────────────────────┐
                              │ Environment Vars    │
                              │ ANTHROPIC_API_KEY   │
                              │ OPENAI_API_KEY      │
                              └─────────────────────┘
```

**Endpoints:**
- `POST /proxy/{provider}/complete` - Non-streaming completion
- `POST /proxy/{provider}/stream` - SSE streaming completion

**Provider Implementations:**
- `loom-llm-anthropic` - Claude API with `x-api-key` auth
- `loom-llm-openai` - GPT API with Bearer token auth
- `loom-llm-vertex` - Google Vertex AI

### 3.5 Adding New Providers

1. Create `crates/loom-llm-{provider}/`
2. Implement `LlmClient` trait with message/tool conversion
3. Implement SSE stream parser using `pin_project_lite`
4. Add to `LlmService` in `loom-llm-service`
5. Configure API key server-side
6. Clients automatically gain access via proxy

---

## 4. Tool System

### 4.1 Architecture

```
┌─────────────┐     Tool Definitions    ┌─────────────┐
│ LLM Provider│ ◄───────────────────── │ToolRegistry │
└─────────────┘                         └──────┬──────┘
       │                                       │
       │ ToolCall                              │ dispatch
       ▼                                       ▼
┌─────────────┐                         ┌─────────────┐
│ Agent State │ ──────────────────────► │    Tool     │
│   Machine   │                         │Implementation│
└─────────────┘                         └──────┬──────┘
       ▲                                       │
       │ ToolResult                            │
       └───────────────────────────────────────┘
                              │
                              ▼
                        ┌──────────┐
                        │ToolContext│
                        │workspace_ │
                        │   root    │
                        └──────────┘
```

### 4.2 Tool Trait

```rust
#[async_trait]
pub trait Tool: Send + Sync {
    fn name(&self) -> &str;
    fn description(&self) -> &str;
    fn input_schema(&self) -> serde_json::Value;
    fn to_definition(&self) -> ToolDefinition;
    async fn invoke(
        &self,
        arguments: serde_json::Value,
        context: &ToolContext,
    ) -> Result<ToolOutput, ToolError>;
}
```

### 4.3 Built-in Tools

| Tool | Purpose | Key Features |
|------|---------|--------------|
| `read_file` | Read file contents | 1MB limit, truncation flag |
| `list_files` | List directory | Recursive, 1000 entry limit |
| `edit_file` | Snippet-based edit | Old/new text replacement, auto-create dirs |
| `bash` | Execute commands | 60s timeout (max 300s), output truncation |
| `oracle` | Query secondary LLM | GPT-4 via server proxy |
| `web_search` | Google search | CSE integration, 10 results max |

### 4.4 Security Model

**Path Validation:**
1. Canonicalize path (resolves symlinks and `..`)
2. Verify path starts with workspace root
3. Return `ToolError::PathOutsideWorkspace` on violation

**Design Rationale for Snippet-Based Editing:**
- LLMs excel at text matching vs line numbers
- Handles merge conflicts gracefully
- Preserves surrounding context
- Atomic edits with verification

### 4.5 Adding New Tools

```rust
// 1. Define input/output structs
#[derive(Deserialize, JsonSchema)]
struct MyToolInput { field: String }

#[derive(Serialize)]
struct MyToolOutput { result: String }

// 2. Implement Tool trait
struct MyTool;

#[async_trait]
impl Tool for MyTool {
    fn name(&self) -> &str { "my_tool" }
    fn description(&self) -> &str { "Does something useful" }
    fn input_schema(&self) -> Value { schemars::schema_for!(MyToolInput) }

    async fn invoke(&self, args: Value, ctx: &ToolContext) -> Result<ToolOutput, ToolError> {
        let input: MyToolInput = serde_json::from_value(args)?;
        // Validate paths against ctx.workspace_root
        // Execute tool logic
        Ok(ToolOutput::json(MyToolOutput { result: "done".into() }))
    }
}

// 3. Register with ToolRegistry
registry.register(Arc::new(MyTool));
```

---

## 5. Thread Persistence System

### 5.1 Data Model

```rust
struct ThreadId(Uuid7);  // Format: T-{uuid7}

struct Thread {
    id: ThreadId,
    workspace_path: PathBuf,
    messages: Vec<MessageSnapshot>,
    agent_state: AgentStateSnapshot,
    visibility: ThreadVisibility,  // Private, Team, Organization, Public
    is_private: bool,              // Never syncs to server if true
    version: u64,                  // Optimistic concurrency
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}
```

### 5.2 Storage Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    SyncingThreadStore                            │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                   LocalThreadStore                           ││
│  │  $XDG_DATA_HOME/loom/threads/{thread_id}.json               ││
│  │  (Atomic writes via temp file + rename)                      ││
│  └─────────────────────────────────────────────────────────────┘│
│                              │                                   │
│                              │ (if !is_private)                  │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                   Server Sync (Background)                   ││
│  │  PUT /v1/threads/{id} with If-Match: {version}              ││
│  │  Pending queue: $XDG_STATE_HOME/loom/sync/pending.json      ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### 5.3 Offline-First Design

1. **Always save locally first** - Never blocks on network
2. **Background sync** - Fire-and-forget spawned tasks
3. **Pending queue** - Failed syncs queued for retry
4. **Privacy guarantee** - `is_private=true` threads never sync

### 5.4 Sync Triggers

- After each inferencing turn (when agent returns to `WaitingForUserInput`)
- On graceful shutdown (SIGINT, EOF, `/exit`)

---

## 6. Weaver: Remote Execution System

### 6.1 Architecture

Weaver provides ephemeral Kubernetes pods for isolated AI agent execution.

```
┌──────────────┐                    ┌──────────────┐
│   loom-cli   │                    │  loom-server │
│              │ ──── WebSocket ──► │              │
│ loom new     │                    │ /api/weaver  │
│ loom attach  │                    │              │
└──────────────┘                    └──────┬───────┘
                                           │
                                           │ K8s API
                                           ▼
                                   ┌──────────────────┐
                                   │   Kubernetes     │
                                   │ loom-weavers NS  │
                                   │                  │
                                   │ ┌──────────────┐ │
                                   │ │  Weaver Pod  │ │
                                   │ │  - loom-cli  │ │
                                   │ │  - workspace │ │
                                   │ │  - git clone │ │
                                   │ └──────────────┘ │
                                   └──────────────────┘
```

### 6.2 Key Features

| Feature | Description |
|---------|-------------|
| **Ephemeral** | 4-48 hour TTL, automatic cleanup |
| **No Database** | Kubernetes is source of truth |
| **Isolated** | Non-root user, dropped capabilities, read-only root FS |
| **Git Integration** | Clone public repos on pod startup |
| **WireGuard Tunnel** | Optional VPN for remote SSH access |
| **Resource Limits** | 16Gi memory, configurable per-weaver |

### 6.3 CLI Commands

```bash
loom new --repo https://github.com/user/repo --branch main --ttl 8h
loom attach <weaver-id>
loom weaver ps
loom weaver delete <weaver-id>
```

### 6.4 Security Model

- ABAC authorization (owner, admin, support roles)
- Pods run as UID 1000:1000
- All capabilities dropped
- No privilege escalation
- Read-only root filesystem

---

## 7. Authentication & Authorization

### 7.1 Authentication Methods

| Method | Use Case | Flow |
|--------|----------|------|
| **OAuth** | Web login | GitHub/Google/Okta → callback → session |
| **Magic Link** | Passwordless email | Request → email → verify → session |
| **Device Code** | CLI/IDE | Display code → poll → token |

### 7.2 Session Management

```rust
enum SessionType {
    Web,      // HttpOnly cookie, 60-day sliding
    Cli,      // Bearer token, 60-day sliding
    VsCode,   // Bearer token, 60-day sliding
}

struct Session {
    user_id: UserId,
    session_type: SessionType,
    created_at: DateTime<Utc>,
    last_used_at: DateTime<Utc>,
    ip_address: IpAddr,
    user_agent: String,
    geo_location: Option<GeoLocation>,
}
```

### 7.3 ABAC Authorization

**Subject Attributes:**
```rust
struct SubjectAttrs {
    user_id: UserId,
    org_memberships: Vec<(OrgId, OrgRole)>,
    team_memberships: Vec<(TeamId, TeamRole)>,
    global_roles: Vec<GlobalRole>,  // system_admin, support, auditor
}
```

**Resource Attributes:**
```rust
struct ResourceAttrs {
    resource_type: ResourceType,
    owner_user_id: Option<UserId>,
    org_id: Option<OrgId>,
    visibility: Visibility,
    is_shared_with_support: bool,
}
```

**Actions:** `Read`, `Write`, `Delete`, `Share`, `UseTool`, `UseLlm`, `ManageOrg`, `Impersonate`

### 7.4 Thread Visibility Policies

| Visibility | Access |
|------------|--------|
| `private` | Owner only |
| `team` | Team members |
| `organization` | All org members |
| `public` | Anyone (read-only for anonymous) |

---

## 8. Configuration System

### 8.1 Precedence Hierarchy

```
Priority 60: CLI Arguments           (--model, --server-url)
Priority 50: Environment Variables   (LOOM_SERVER_*)
Priority 40: Workspace Config        (.loom/config.toml)
Priority 30: User Config             (~/.config/loom/config.toml)
Priority 20: System Config           (/etc/loom/config.toml)
Priority 10: Built-in Defaults       (compiled into binary)
```

### 8.2 Configuration Structure

```toml
[global]
default_provider = "anthropic"
default_model = "claude-sonnet-4-20250514"

[providers.anthropic]
type = "anthropic"

[providers.openai]
type = "openai"

[tools]
max_workspace_size_mb = 100
command_timeout_secs = 60
exclude_patterns = ["node_modules", ".git", "target"]

[retry]
max_attempts = 3
base_delay_ms = 200
max_delay_ms = 5000
backoff_factor = 2.0
jitter = true

[logging]
level = "info"
format = "pretty"  # or "json"
```

### 8.3 XDG Compliance

| Purpose | Path |
|---------|------|
| Config | `$XDG_CONFIG_HOME/loom/` (~/.config/loom/) |
| Data | `$XDG_DATA_HOME/loom/` (~/.local/share/loom/) |
| Cache | `$XDG_CACHE_HOME/loom/` (~/.cache/loom/) |
| State | `$XDG_STATE_HOME/loom/` (~/.local/state/loom/) |

---

## 9. Error Handling

### 9.1 Error Type Hierarchy

```rust
enum AgentError {
    Llm(LlmError),
    Tool(ToolError),
    InvalidState { expected: &'static str, actual: &'static str },
    Io(std::io::Error),
    Timeout { operation: String },
    Internal(String),
}

enum LlmError {
    Http(String),              // Transient
    Api(String),               // Maybe transient
    Timeout,                   // Transient
    InvalidResponse(String),   // Permanent
    RateLimited { retry_after_secs: Option<u64> },  // Transient
}

enum ToolError {
    NotFound(String),
    InvalidArguments(String),
    Io(String),
    Timeout,
    PathOutsideWorkspace(PathBuf),
    FileNotFound(PathBuf),
    Serialization(String),
}
```

### 9.2 Retry Strategy

```rust
struct RetryConfig {
    max_attempts: u32,         // Default: 3
    base_delay: Duration,      // Default: 200ms
    max_delay: Duration,       // Default: 5s
    backoff_factor: f64,       // Default: 2.0
    jitter: bool,              // Default: true
    retryable_statuses: Vec<u16>,  // [429, 408, 502, 503, 504]
}
```

**Backoff Calculation:**
```
delay = min(base_delay × backoff_factor^attempt, max_delay)
if jitter: delay *= random(0.5, 1.5)
```

### 9.3 Error Recovery Flow

1. LLM error → increment retry counter
2. Check against max_retries (default: 3)
3. If retries available → transition to Error state
4. External timer fires RetryTimeoutFired
5. Retry → transition back to CallingLlm
6. If max retries exceeded → surface to user

---

## 10. IDE Integration (ACP)

### 10.1 Agent Client Protocol

Loom implements the Agent Client Protocol (ACP) for IDE integration via JSON-RPC over stdio.

```
┌─────────────────┐     JSON-RPC/stdio     ┌─────────────────┐
│   VS Code       │ ◄────────────────────► │  loom acp-agent │
│   Extension     │                        │                 │
│                 │    session/new         │  ┌───────────┐  │
│   ChatView  ────┼───────────────────────►│  │LoomAcpAgent│  │
│                 │    session/prompt      │  └─────┬─────┘  │
│                 │◄───────────────────────┼────────┘        │
│                 │    session/update      │                 │
└─────────────────┘                        └─────────────────┘
```

### 10.2 Session Lifecycle

```rust
// 1. Initialize
initialize() → AgentCapabilities

// 2. Create session (maps to ThreadId)
session/new { cwd } → SessionId

// 3. Load existing session
session/load { session_id } → Ok

// 4. Send prompt
session/prompt { session_id, content } → PromptResponse
  // Streams session/update notifications for:
  // - TextDelta
  // - ToolCallStart/Finish
  // - StopReason

// 5. Cancel
session/cancel { session_id } → Ok
```

### 10.3 VS Code Extension Architecture

```typescript
interface ExtensionComponents {
    AgentProcessManager: manages loom acp-agent subprocess
    AcpClient: wraps JSON-RPC communication
    SessionManager: persists sessions to workspaceState
    ChatController: orchestrates chat flow
    ChatViewProvider: webview UI
}
```

---

## 11. Analytics System

### 11.1 PostHog-Inspired Design

```rust
struct Person {
    id: PersonId,
    org_id: OrgId,
    properties: serde_json::Value,
}

struct Event {
    id: EventId,
    person_id: Option<PersonId>,
    distinct_id: String,
    event_name: String,
    properties: serde_json::Value,
    timestamp: DateTime<Utc>,
}
```

### 11.2 Identity Resolution

1. Anonymous user gets UUIDv7
2. Events tagged with `distinct_id`
3. `identify(anonymous_id, user_id)` links identities
4. System merges persons, properties, events
5. Future events resolve to same Person

### 11.3 API Keys

- **Write-only** (client-safe): capture events only
- **ReadWrite** (server-only): query events, persons
- Format: `loom_analytics_{type}_{random}`

---

## 12. Spool: Version Control

Spool is a fork of jj (Jujutsu) with tapestry-themed terminology.

### 12.1 Terminology Mapping

| Spool Term | Git/jj Equivalent |
|------------|-------------------|
| Stitch | Change |
| Knot | Commit |
| Shuttle | Working copy |
| Pin | Bookmark/branch |
| Tangle/Snag | Conflict |
| Rethread | Rebase |
| Ply | Squash |
| Unpick | Undo |

### 12.2 Agent Integration Benefits

- Auto-creates stitches on tool execution
- Full undo capability via unpick
- Uses history for context in LLM prompts
- Automatic rebasing handles parallel changes

---

## 13. Design Patterns

### 13.1 Patterns Used

| Pattern | Usage |
|---------|-------|
| **Strategy** | `LlmClient` trait for runtime provider selection |
| **Registry** | `ToolRegistry` for dynamic tool lookup |
| **Builder** | Fluent configuration APIs |
| **Hook** | `PostToolsHook` for infrastructure operations |
| **Discriminated Union** | Rust enums encode states with data |
| **Type State** | `ConfigLayer` (partial) vs `LoomConfig` (complete) |

### 13.2 Async Architecture

- All I/O async with Tokio
- Streaming LLM responses via SSE
- Concurrent tool execution
- `#[instrument]` for structured tracing
- `pin_project_lite` for safe stream wrappers

---

## 14. Key Architectural Decisions

### 14.1 Server-Side LLM Proxy

**Decision:** Route all LLM calls through server, never expose API keys to clients.

**Benefits:**
- Security: Keys never in client binaries or network traffic
- Centralized: Rate limiting, logging, cost tracking
- Flexibility: Change providers without client updates

### 14.2 Deterministic State Machine

**Decision:** Pure, synchronous state machine with explicit events and actions.

**Benefits:**
- Testable: Unit test transitions without I/O
- Predictable: Same input always produces same output
- Debuggable: Full state history available

### 14.3 Snippet-Based Editing

**Decision:** Use text matching for edits instead of line numbers.

**Benefits:**
- LLM-friendly: Models excel at text matching
- Robust: Works across file modifications
- Verifiable: Can confirm exact match before edit

### 14.4 Offline-First Persistence

**Decision:** Always save locally, sync in background.

**Benefits:**
- Reliability: Never lose work due to network
- Speed: No blocking on remote calls
- Privacy: Local-only option available

### 14.5 Kubernetes-Based Remote Execution

**Decision:** Use ephemeral K8s pods for isolated agent execution.

**Benefits:**
- Isolation: Full container security
- Scalability: K8s handles scheduling
- Simplicity: No custom infrastructure

---

## 15. Extension Points

### 15.1 Adding New LLM Provider

1. Create `crates/loom-llm-{provider}/`
2. Implement `LlmClient` trait
3. Handle message/tool format conversion
4. Implement SSE stream parser
5. Add to `LlmService`
6. Configure API key environment variable

### 15.2 Adding New Tool

1. Define input/output structs with JSON Schema
2. Implement `Tool` trait
3. Validate paths against workspace root
4. Register with `ToolRegistry`
5. Add property-based tests

### 15.3 Adding New Agent State

1. Add `AgentState` enum variant
2. Update `handle_event()` for transitions
3. Add corresponding `AgentAction` if needed
4. Extend logging and metrics

### 15.4 Adding New Auth Provider

1. Create `crates/loom-auth-{provider}/`
2. Implement OAuth flow
3. Add callback handler
4. Register in auth configuration

---

## 16. Build System

### 16.1 Nix (Preferred)

```bash
# Build individual crates
nix build .#loom-cli-c2n
nix build .#loom-server-c2n

# Development shell
nix develop

# Update after Cargo.lock changes
cargo2nix-update
```

### 16.2 Cargo (Development)

```bash
cargo build --workspace
cargo test --workspace
cargo clippy --workspace -- -D warnings
```

### 16.3 Performance Optimizations

```toml
[profile.dev]
debug = 1
split-debuginfo = "unpacked"

[profile.dev-fast]
inherits = "dev"
debug = 0
```

---

## 17. Deployment

### 17.1 Auto-Deployment

```bash
git push origin trunk
# NixOS server checks every 10 seconds
# Verify: cat /var/lib/nixos-auto-update/deployed-revision
```

### 17.2 Database Migrations

- Location: `crates/loom-server/migrations/`
- Format: `NNN_description.sql`
- After adding: run `cargo2nix-update` to force rebuild

---

## 18. Recommendations for Multi-Agent Systems

Based on Loom's architecture, here are recommendations for building multi-agent autonomous coding systems:

### 18.1 Core Principles

1. **Deterministic State Machine** - Make agent behavior predictable and testable
2. **Trait-Based Abstractions** - Enable runtime polymorphism and easy mocking
3. **Explicit Error Handling** - Use typed errors with retry/recovery strategies
4. **Security by Design** - Never expose secrets to clients, validate all paths

### 18.2 Architecture Recommendations

1. **Separate concerns into crates/modules** - Core, providers, tools, persistence
2. **Use streaming for LLM responses** - Essential for good UX
3. **Implement offline-first persistence** - Never lose work
4. **Provide multiple interfaces** - CLI, web, IDE integration
5. **Build observability in** - Structured logging, metrics, analytics

### 18.3 Multi-Agent Considerations

1. **Session isolation** - Each agent instance has its own thread/context
2. **Shared tool registry** - Common tools across agents
3. **Centralized LLM proxy** - Cost control, rate limiting
4. **ABAC for resources** - Fine-grained access control
5. **Ephemeral execution** - Kubernetes pods for isolation

### 18.4 Testing Strategy

1. **Property-based tests** for state machine invariants
2. **Unit tests** for tool implementations
3. **Integration tests** with mock LLM clients
4. **Manual checklist** for UI/UX flows

---

## Appendix A: Crate Dependency Graph

```
loom-core (foundation)
    ├── loom-http (HTTP utilities)
    ├── loom-secret (secret management)
    └── loom-i18n (internationalization)

loom-llm-* (providers, depend on loom-core)
    ├── loom-llm-anthropic
    ├── loom-llm-openai
    └── loom-llm-vertex

loom-llm-service (depends on all providers)
    └── loom-llm-proxy (client-side proxy)

loom-tools (depends on loom-core)

loom-thread (depends on loom-core)

loom-server (depends on everything)
    ├── loom-server-api
    ├── loom-server-db
    └── loom-server-session

loom-cli (depends on most crates)
    ├── loom-cli-config
    ├── loom-cli-credentials
    └── loom-cli-tools

loom-acp (depends on loom-core, loom-thread, loom-tools)

loom-weaver (depends on loom-k8s)
```

---

## Appendix B: Environment Variables

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | Anthropic API authentication |
| `OPENAI_API_KEY` | OpenAI API authentication |
| `LOOM_SERVER_URL` | Server URL for CLI |
| `LOOM_SERVER_*` | Server configuration overrides |
| `XDG_CONFIG_HOME` | Config directory override |
| `XDG_DATA_HOME` | Data directory override |

---

## Appendix C: Key Files

| Path | Purpose |
|------|---------|
| `specs/` | Design specifications (51 files) |
| `AGENTS.md` | Agent guidelines for working with codebase |
| `Cargo.toml` | Workspace configuration |
| `flake.nix` | Nix build configuration |
| `crates/loom-core/` | Core abstractions |
| `crates/loom-server/` | HTTP server |
| `crates/loom-cli/` | Command-line interface |
| `web/loom-web/` | Svelte frontend |
| `ide/vscode/` | VS Code extension |

---

*Generated from analysis of https://github.com/ghuntley/loom*
*Last updated: 2026-01-17*
