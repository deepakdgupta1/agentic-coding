# ACFS Integration Specification

## Overview

ACFS Canvas is built as an extension of the existing ACFS infrastructure, providing a web-based GUI layer on top of the proven CLI tooling. This document specifies how each ACFS component integrates with the Canvas application.

---

## Component Integration Map

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ACFS Canvas (Web UI)                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│   │ Project │  │ Canvas  │  │ Agent   │  │  Task   │  │ Deploy  │ │
│   │ Wizard  │  │  View   │  │ Panel   │  │  List   │  │  Panel  │ │
│   └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘ │
│        │            │            │            │            │       │
└────────┼────────────┼────────────┼────────────┼────────────┼───────┘
         │            │            │            │            │
         ▼            ▼            ▼            ▼            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       Integration Layer (API/WebSocket)             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│   │  acfs   │  │   NTM   │  │  Agent  │  │  Beads  │  │  CASS   │ │
│   │ newproj │  │         │  │  Mail   │  │  (br)   │  │         │ │
│   └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘ │
│                                                                     │
│                            ┌─────────┐                              │
│                            │   UBS   │                              │
│                            └─────────┘                              │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 1. NTM (Named Tmux Manager)

### Purpose in Canvas
Spawns and manages AI agent sessions, sends prompts, and monitors agent status.

### Integration Points

| Canvas Feature | NTM Command | Data Flow |
|----------------|-------------|-----------|
| Spawn agents | `ntm spawn <project> --cc=N --cod=N --gmi=N` | Canvas → NTM |
| Agent status | `ntm status <project>` | NTM → Canvas |
| Send prompt | `ntm send <project> "prompt"` | Canvas → NTM |
| Pause agents | `ntm pause <project>` | Canvas → NTM |
| Resume agents | `ntm resume <project>` | Canvas → NTM |
| Kill agent | `ntm kill <project> <agent>` | Canvas → NTM |

### API Design

```typescript
interface NTMService {
  // Spawn a new agent session
  spawn(project: string, config: {
    claudeCount: number;
    codexCount: number;
    geminiCount: number;
  }): Promise<SessionInfo>;

  // Get current session status
  getStatus(project: string): Promise<AgentStatus[]>;

  // Send prompt to agents
  sendPrompt(project: string, prompt: string, target?: AgentTarget): Promise<void>;

  // Pause/resume/kill operations
  pause(project: string, agentId?: string): Promise<void>;
  resume(project: string, agentId?: string): Promise<void>;
  kill(project: string, agentId: string): Promise<void>;
}

interface AgentStatus {
  id: string;
  type: 'claude' | 'codex' | 'gemini';
  name: string;
  status: 'idle' | 'working' | 'paused' | 'error';
  currentTask?: string;
  uptime: number;
}
```

### Real-Time Events (WebSocket)

```typescript
// Events emitted by NTM
type NTMEvent =
  | { type: 'agent_spawned'; agent: AgentStatus }
  | { type: 'agent_started_task'; agentId: string; task: string }
  | { type: 'agent_completed_task'; agentId: string; task: string }
  | { type: 'agent_error'; agentId: string; error: string }
  | { type: 'agent_idle'; agentId: string };
```

### Affected Stories
- E3-S1: Agent Status Dashboard
- E3-S3: Pause/Resume Agent Work
- E3-S6: Spawn Additional Agents

---

## 2. Agent Mail (MCP)

### Purpose in Canvas
Facilitates agent-to-agent coordination, file reservations, and messaging.

### Integration Points

| Canvas Feature | Agent Mail Function | Data Flow |
|----------------|---------------------|-----------|
| Agent registration | `register_agent()` | Canvas → Mail |
| View messages | `fetch_inbox()` | Mail → Canvas |
| File reservations | `file_reservation_paths()` | Canvas ↔ Mail |
| Search messages | `search_messages()` | Canvas → Mail |
| Message threads | `send_message()`, `reply_message()` | Canvas ↔ Mail |

### API Design

```typescript
interface AgentMailService {
  // Project management
  ensureProject(projectKey: string): Promise<void>;

  // Agent registration
  registerAgent(projectKey: string, program: string, model: string): Promise<AgentIdentity>;

  // Messaging
  fetchInbox(projectKey: string, since?: Date): Promise<Message[]>;
  sendMessage(to: string[], subject: string, body: string): Promise<string>;
  searchMessages(query: string, limit: number): Promise<Message[]>;

  // File reservations
  getReservations(projectKey: string): Promise<FileReservation[]>;
  reserveFiles(paths: string[], ttl: number, exclusive: boolean): Promise<void>;
  releaseReservations(): Promise<void>;
}

interface Message {
  id: string;
  from: string;
  to: string[];
  subject: string;
  body: string;
  timestamp: Date;
  threadId?: string;
}

interface FileReservation {
  agentName: string;
  paths: string[];
  exclusive: boolean;
  expiresAt: Date;
  reason?: string;
}
```

### Real-Time Events (WebSocket)

```typescript
type AgentMailEvent =
  | { type: 'message_received'; message: Message }
  | { type: 'file_reserved'; reservation: FileReservation }
  | { type: 'file_released'; paths: string[]; agentName: string }
  | { type: 'reservation_conflict'; agent1: string; agent2: string; paths: string[] };
```

### Affected Stories
- E3-S2: Plain-English Activity Logs
- E3-S4: Agent-to-Agent Communication View
- E3-S5: Redirect Agent to Different Task

---

## 3. Beads (br/bv)

### Purpose in Canvas
Manages task DAG, tracks progress, and provides dependency-aware planning.

### Integration Points

| Canvas Feature | Beads Command | Data Flow |
|----------------|---------------|-----------|
| Initialize project | `br init` | Canvas → Beads |
| Create tasks | `br create` | Canvas → Beads |
| Get task list | `br list --json` | Beads → Canvas |
| Get ready tasks | `br ready --json` | Beads → Canvas |
| Update task status | `br update <id>` | Canvas → Beads |
| Close task | `br close <id>` | Canvas → Beads |
| Robot triage | `bv --robot-triage` | Beads → Canvas |
| Sync to file | `br sync --flush-only` | Canvas → Beads |

### API Design

```typescript
interface BeadsService {
  // Project initialization
  init(projectPath: string): Promise<void>;

  // Task management
  createTask(title: string, options?: TaskOptions): Promise<Task>;
  listTasks(filter?: TaskFilter): Promise<Task[]>;
  getReadyTasks(): Promise<Task[]>;
  updateTask(id: string, updates: TaskUpdate): Promise<Task>;
  closeTask(id: string, reason: string): Promise<void>;

  // Analysis
  getRobotTriage(): Promise<TriageResult>;
  getDependencyGraph(): Promise<DependencyGraph>;

  // Sync
  sync(): Promise<void>;
}

interface Task {
  id: string;
  title: string;
  description?: string;
  status: 'pending' | 'in_progress' | 'completed' | 'blocked';
  priority: number;
  assignee?: string;
  component?: string;
  dependencies: string[];
  dependents: string[];
  createdAt: Date;
  updatedAt: Date;
}

interface DependencyGraph {
  nodes: Task[];
  edges: { from: string; to: string }[];
  criticalPath: string[];
}
```

### Real-Time Events

```typescript
type BeadsEvent =
  | { type: 'task_created'; task: Task }
  | { type: 'task_updated'; task: Task }
  | { type: 'task_completed'; task: Task }
  | { type: 'task_blocked'; task: Task; blockedBy: string[] };
```

### Affected Stories
- E4-S1: Task Breakdown View
- E4-S2: Progress Visualization
- E4-S3: Blocked Task Visualization
- E4-S5: Manual Task Flagging

---

## 4. CASS (Coding Agent Session Search)

### Purpose in Canvas
Provides session history search and retrieval for learning from past work.

### Integration Points

| Canvas Feature | CASS Functionality | Data Flow |
|----------------|-------------------|-----------|
| Search history | `cass search <query>` | Canvas → CASS |
| Get context | `cm context <topic>` | CASS → Canvas |
| Reflect on session | `cm reflect` | Canvas → CASS |
| Session export | CASS export | CASS → Canvas |

### API Design

```typescript
interface CASSService {
  // Search
  search(query: string, options?: SearchOptions): Promise<SessionMatch[]>;

  // Context retrieval
  getContext(topic: string): Promise<ContextResult>;

  // Reflection
  reflect(summary: string): Promise<void>;

  // Session history
  getSessions(filter?: SessionFilter): Promise<SessionSummary[]>;
  getSessionDetail(sessionId: string): Promise<SessionDetail>;
}

interface SessionMatch {
  sessionId: string;
  timestamp: Date;
  relevance: number;
  snippet: string;
  agent: string;
  project: string;
}

interface ContextResult {
  topic: string;
  relevantPatterns: string[];
  suggestedApproaches: string[];
  relatedSessions: string[];
}
```

### Affected Stories
- E1-S5: Complexity and Scope Estimate (uses past project data)
- E8-S2: Project Change Timeline
- E5-S4: Concept-Based Code Search

---

## 5. UBS (Ultimate Bug Scanner)

### Purpose in Canvas
Scans generated code for quality issues before deployment.

### Integration Points

| Canvas Feature | UBS Command | Data Flow |
|----------------|-------------|-----------|
| Scan files | `ubs <files>` | Canvas → UBS |
| Full scan | `ubs .` | Canvas → UBS |
| Get issues | Parse UBS output | UBS → Canvas |

### API Design

```typescript
interface UBSService {
  // Scanning
  scanFiles(files: string[]): Promise<ScanResult>;
  scanDirectory(path: string): Promise<ScanResult>;

  // Results
  getIssuesByFile(file: string): Promise<Issue[]>;
  getIssueSeverityCount(): Promise<SeverityCounts>;
}

interface ScanResult {
  totalFiles: number;
  filesWithIssues: number;
  issues: Issue[];
  passed: boolean;
}

interface Issue {
  file: string;
  line: number;
  severity: 'error' | 'warning' | 'info';
  message: string;
  rule: string;
  suggestion?: string;
}
```

### Affected Stories
- E6-S1: Automated Test Results Display
- E6-S4: Test Coverage Display

---

## 6. ACFS Project Creation

### Purpose in Canvas
Creates new projects with proper structure, AGENTS.md, and tooling.

### Integration Points

| Canvas Feature | ACFS Command | Data Flow |
|----------------|--------------|-----------|
| Create project | `acfs newproj <name>` | Canvas → ACFS |
| Detect tech stack | `newproj_detect.sh` | ACFS → Canvas |
| Generate AGENTS.md | Template rendering | Canvas → ACFS |

### API Design

```typescript
interface ACFSProjectService {
  // Project creation
  createProject(name: string, path?: string): Promise<ProjectInfo>;

  // Tech detection
  detectTechStack(path: string): Promise<TechStack>;

  // AGENTS.md generation
  generateAgentsMd(spec: ProjectSpecification): Promise<string>;

  // Project status
  getProjectStatus(path: string): Promise<ProjectStatus>;
}

interface ProjectInfo {
  name: string;
  path: string;
  techStack: TechStack;
  beadsInitialized: boolean;
  agentsMdGenerated: boolean;
}

interface TechStack {
  languages: string[];
  frameworks: string[];
  buildTools: string[];
  detectedFrom: string[];
}
```

### Affected Stories
- E1-S3: Project Type Selection
- E1-S4: Auto-Generated Specification Review

---

## 7. Deployment Integration

### Purpose in Canvas
Deploy built applications to staging and production environments.

### Integration Points

| Canvas Feature | Integration | Data Flow |
|----------------|-------------|-----------|
| Deploy staging | Vercel/Railway CLI | Canvas → Provider |
| Deploy production | Vercel/Railway CLI | Canvas → Provider |
| Domain setup | Provider API | Canvas → Provider |
| Deployment logs | Provider API | Provider → Canvas |

### API Design

```typescript
interface DeploymentService {
  // Deployment
  deployToStaging(project: string): Promise<DeploymentResult>;
  deployToProduction(project: string): Promise<DeploymentResult>;

  // Status
  getDeploymentStatus(deploymentId: string): Promise<DeploymentStatus>;
  getDeploymentLogs(deploymentId: string): Promise<string[]>;

  // History
  getDeploymentHistory(project: string): Promise<Deployment[]>;

  // Rollback
  rollback(deploymentId: string): Promise<DeploymentResult>;

  // Domain
  configureDomain(domain: string): Promise<DomainConfig>;
  verifyDomain(domain: string): Promise<boolean>;
}

interface DeploymentResult {
  id: string;
  url: string;
  status: 'pending' | 'building' | 'deploying' | 'success' | 'failed';
  startedAt: Date;
  completedAt?: Date;
  error?: string;
}
```

### Affected Stories
- E7-S1: One-Click Staging Deployment
- E7-S2: One-Click Production Deployment
- E7-S3: Deployment Status and Logs
- E7-S4: Custom Domain Configuration
- E7-S5: Deployment Rollback

---

## Communication Patterns

### REST API Endpoints

```
POST   /api/projects                  # Create project
GET    /api/projects/:id              # Get project details
GET    /api/projects/:id/tasks        # List tasks
POST   /api/projects/:id/tasks        # Create task
PATCH  /api/projects/:id/tasks/:tid   # Update task
GET    /api/projects/:id/agents       # List agents
POST   /api/projects/:id/agents/spawn # Spawn agents
POST   /api/projects/:id/deploy       # Deploy project
```

### WebSocket Events

```
Connection: /ws/projects/:id

Events (Server → Client):
- agent:status_changed
- agent:task_started
- agent:task_completed
- task:created
- task:updated
- message:received
- file:reserved
- deployment:progress

Commands (Client → Server):
- agent:pause
- agent:resume
- agent:send_prompt
- task:update
```

---

## Data Flow Example: Build Phase

```
1. User clicks "Begin Build"
   └── Canvas → POST /api/projects/:id/build

2. Backend spawns agents
   └── NTM spawn command executed
   └── WebSocket: agent:spawned events

3. Agents pick up tasks
   └── Beads br ready → tasks assigned
   └── Agent Mail: file reservations
   └── WebSocket: task:started events

4. Agent completes work
   └── Agent Mail: message sent
   └── Beads: task status updated
   └── WebSocket: task:completed event

5. Canvas updates UI
   └── Component node changes color
   └── Progress bar increments
   └── Activity log entry added
```

---

## Security Considerations

1. **Agent Isolation:** Agents run in sandboxed tmux sessions
2. **File Access:** Agent Mail enforces reservation exclusivity
3. **Deployment Credentials:** Stored securely, never exposed to frontend
4. **WebSocket Auth:** Token-based authentication for real-time connections
5. **Rate Limiting:** API endpoints protected against abuse
