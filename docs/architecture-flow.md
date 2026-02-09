# ACFS Architecture Flow & System Diagrams

> Agentic Coding Flywheel Setup — from a single `curl` command to a fully operational multi-agent development environment.

---

## 1. High-Level Architecture Flow

```mermaid
flowchart TB
    subgraph UserLayer["User Layer"]
        U([User]) -->|"curl | bash"| CLI[install.sh<br/>5,743 lines]
        U -->|Browser| WIZ[Wizard UI<br/>Next.js 16 / React 19]
        WIZ -->|Generates curl command| CLI
    end

    subgraph Orchestration["Orchestration Engine"]
        CLI -->|Parse args| ARGS[CLI Arg Parser<br/>--yes --mode --skip --only]
        ARGS -->|Validate| CONTRACT[Contract Validation<br/>preflight.sh + autofix.sh]
        CONTRACT -->|Initialize| STATE[State Manager<br/>state.json v3]
        STATE -->|Phase loop| EXEC[Phase Executor<br/>9 sequential phases]
    end

    subgraph ManifestSystem["Manifest System (SSOT)"]
        MANIFEST[(acfs.manifest.yaml<br/>80+ modules)] -->|Parse + Validate| GEN[Generator<br/>generate.ts + Zod]
        GEN -->|Emit| SCRIPTS[Generated Scripts<br/>install_*.sh × 11]
        GEN -->|Emit| WEBDATA[Web Catalog Data<br/>tools.ts / tldr.ts]
        GEN -->|Emit| DOCTOR[Doctor Checks<br/>doctor_checks.sh]
    end

    subgraph ExecutionCore["Execution Core"]
        EXEC -->|For each module| MOD{Module Runner}
        MOD -->|1| CHECK[installed_check<br/>command -v ...]
        CHECK -->|Already installed| SKIP[Skip Module]
        CHECK -->|Not found| INSTALL[Execute install commands]
        INSTALL -->|Then| VERIFY[Run verify commands]
        VERIFY --> NEXT[Next Module]
        SKIP --> NEXT
    end

    subgraph SecurityLayer["Security Layer"]
        SEC[security.sh] -->|HTTPS enforcement| INSTALL
        SEC -->|SHA256 verify| CHECKSUMS[(checksums.yaml)]
        SEC -->|Runner allowlist| RUNNERS["bash | sh only"]
    end

    subgraph MemorySystem["Memory & State"]
        STATE --- STATEFILE[("~/.acfs/state.json<br/>Phase tracking<br/>Error context<br/>Ubuntu upgrade state")]
        ERR[error_tracking.sh] --- ERRCTX["CURRENT_PHASE<br/>CURRENT_STEP<br/>LAST_ERROR_*"]
        ERR -->|Persist| STATEFILE
        LOG[logging.sh] -->|Capture| LOGFILE[("~/.acfs/logs/<br/>install-*.log")]
    end

    subgraph EventSystem["Event System"]
        EXEC -->|set_phase| EV_PHASE[Phase Transition Event]
        MOD -->|try_step| EV_STEP[Step Execution Event]
        INSTALL -->|on error| EV_ERR[Error Event]
        EV_PHASE --> STATE
        EV_STEP --> LOG
        EV_ERR --> ERR
    end

    subgraph OutputLayer["Output: Configured Environment"]
        NEXT -->|Phase 6| AGENTS[Coding Agents<br/>Claude · Codex · Gemini · Amp]
        NEXT -->|Phase 8| STACK[Multi-Agent Stack<br/>NTM · MCP Mail · UBS · CASS]
        NEXT -->|Phase 9| SERVICES[Services<br/>tmux · dashboard · onboard]
        AGENTS --> READY([Agent-Ready VPS])
        STACK --> READY
        SERVICES --> READY
    end

    SCRIPTS -->|Source| EXEC
    MANIFEST -.->|Defines| MOD

    classDef user fill:#e0f2fe,stroke:#0284c7,color:#0c4a6e
    classDef engine fill:#fef3c7,stroke:#d97706,color:#78350f
    classDef manifest fill:#dcfce7,stroke:#16a34a,color:#14532d
    classDef exec fill:#fce7f3,stroke:#db2777,color:#831843
    classDef security fill:#fee2e2,stroke:#dc2626,color:#7f1d1d
    classDef memory fill:#e0e7ff,stroke:#4f46e5,color:#312e81
    classDef event fill:#f3e8ff,stroke:#9333ea,color:#581c87
    classDef output fill:#d1fae5,stroke:#059669,color:#064e3b

    class U,WIZ user
    class CLI,ARGS,CONTRACT,STATE,EXEC engine
    class MANIFEST,GEN,SCRIPTS,WEBDATA,DOCTOR manifest
    class MOD,CHECK,SKIP,INSTALL,VERIFY,NEXT exec
    class SEC,CHECKSUMS,RUNNERS security
    class STATEFILE,ERR,ERRCTX,LOG,LOGFILE memory
    class EV_PHASE,EV_STEP,EV_ERR event
    class AGENTS,STACK,SERVICES,READY output
```

---

## 2. Detailed Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant W as Wizard UI
    participant I as install.sh
    participant C as contract.sh
    participant A as autofix.sh
    participant S as state.sh
    participant M as manifest (YAML)
    participant G as generate.ts
    participant SC as security.sh
    participant CK as checksums.yaml
    participant EX as Phase Executor
    participant ET as error_tracking.sh
    participant L as logging.sh
    participant AG as agents.sh
    participant SV as services-setup.sh
    participant OB as onboard.sh

    rect rgb(224,242,254)
        Note over U,W: Phase 0 — User Setup
        U->>W: Opens agent-flywheel.com/wizard
        W->>W: 14-step guided configuration
        W->>U: Generated curl command
        U->>I: curl -fsSL ... | bash -s -- --yes --mode vibe
    end

    rect rgb(254,243,199)
        Note over I,A: Phase 0 — Pre-Flight
        I->>I: Parse CLI args (--yes, --mode, --skip, --only)
        I->>C: Run contract validation
        C->>C: Check bash 4.0+, curl, jq, EUID
        C-->>I: Pass / Fail
        I->>A: Auto-fix detected issues
        A->>A: Patch missing deps, fix permissions
        A-->>I: Fixed / Cannot fix
    end

    rect rgb(220,252,231)
        Note over I,G: Manifest Processing
        I->>M: Load acfs.manifest.yaml
        M->>G: Parse + Zod validate
        G->>G: Generate install_*.sh (×11)
        G->>G: Generate doctor_checks.sh
        G->>G: Generate manifest_index.sh
        G-->>I: Scripts ready
    end

    rect rgb(224,231,255)
        Note over I,S: State Initialization
        I->>S: init_state() or load existing
        S->>S: Read ~/.acfs/state.json
        alt Resuming from checkpoint
            S-->>I: completed_phases, current_phase
            Note over I: Skip completed phases
        else Fresh install
            S-->>I: Empty state (schema v3)
        end
    end

    rect rgb(252,231,243)
        Note over I,L: Phase 1 — Base System
        I->>EX: Execute Phase 1 modules
        EX->>ET: set_phase("base_system")
        ET->>S: state_phase_start()
        loop Each module in phase
            EX->>EX: installed_check (command -v curl, git, jq)
            alt Already installed
                EX->>L: log_step "Skipping (already installed)"
            else Not installed
                EX->>SC: Validate download URLs
                SC->>CK: Load SHA256 checksums
                SC-->>EX: Verified / Reject
                EX->>EX: apt-get install -y ...
                EX->>EX: Run verify commands
                EX->>L: log_success "Installed"
            end
        end
        EX->>ET: clear_phase()
        ET->>S: state_phase_complete()
    end

    rect rgb(254,226,226)
        Note over I,AG: Phases 2–5 — Users, Filesystem, Shell, Languages
        I->>EX: Execute Phases 2-5 (same pattern)
        Note over EX: Phase 2: ubuntu user + sudo<br/>Phase 3: /data/projects, ~/.acfs<br/>Phase 4: zsh, oh-my-zsh, p10k<br/>Phase 5: bun, uv, rustup, go, ruby, java
        EX->>S: Track each phase
    end

    rect rgb(209,250,229)
        Note over I,AG: Phase 6 — Coding Agents
        I->>AG: install_agent("claude")
        AG->>SC: Verify @anthropic-ai/claude-code checksum
        SC-->>AG: OK
        AG->>AG: bun add -g @anthropic-ai/claude-code@stable
        AG->>AG: claude --version (verify)
        AG-->>I: Claude installed

        I->>AG: install_agent("codex")
        AG->>AG: bun add -g @openai/codex@latest
        alt Latest fails
            AG->>AG: Fallback to v0.87.0
        end
        AG-->>I: Codex installed

        I->>AG: install_agent("gemini")
        AG->>AG: bun add -g @google/gemini-cli@latest
        AG-->>I: Gemini installed
    end

    rect rgb(243,232,255)
        Note over I,SV: Phases 7–9 — Cloud Tools, Stack, Finalize
        I->>EX: Phase 7: vault, wrangler, supabase
        I->>EX: Phase 8: NTM, MCP Mail, UBS, CASS, etc.
        I->>SV: Phase 9: services-setup.sh
        SV->>SV: Start tmux, dashboard, tailscale
        SV-->>I: Services running
    end

    rect rgb(220,252,231)
        Note over I,OB: Onboarding
        I->>OB: Launch onboard.sh TUI
        OB->>U: 14 interactive lessons
        OB-->>I: Onboarding complete
    end

    rect rgb(224,242,254)
        Note over I,S: Completion
        I->>S: state_phase_complete("finalize")
        I->>L: Log session summary
        I->>U: Exit 0 — VPS ready
    end
```

---

## 3. Component Interaction Matrix

| Component | install.sh | state.sh | error_tracking | logging | security | manifest | generate.ts | agents.sh | services | onboard | Wizard UI |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| **install.sh** | — | R/W | R/W | W | R | R | — | Call | Call | Call | — |
| **state.sh** | Called | — | W | — | — | — | — | — | — | — | — |
| **error_tracking.sh** | Called | W | — | W | — | — | — | — | — | — | — |
| **logging.sh** | Called | — | — | — | — | — | — | — | — | — | — |
| **security.sh** | Called | — | — | W | — | — | — | — | — | — | — |
| **acfs.manifest.yaml** | R | — | — | — | — | — | R | — | — | — | — |
| **generate.ts** | — | — | — | — | — | R | — | — | — | — | W |
| **agents.sh** | Called | — | — | W | R | — | — | — | — | — | — |
| **services-setup.sh** | Called | — | — | W | — | — | — | — | — | — | — |
| **onboard.sh** | Called | R | — | — | — | — | — | — | — | — | — |
| **Wizard UI** | Generates cmd | — | — | — | — | — | R (data) | — | — | — | — |
| **contract.sh** | Called | — | — | W | — | — | — | — | — | — | — |
| **autofix.sh** | Called | — | — | W | — | — | — | — | — | — | — |
| **checksums.yaml** | — | — | — | — | R | — | — | — | — | — | — |
| **doctor.sh** | — | R | — | W | — | R | — | — | — | — | — |

**Legend:** R = Reads from, W = Writes to, R/W = Both, Call = Invokes, Called = Invoked by, — = No interaction

---

## 4. Data Transformations

Shows how a short user prompt transforms through the system into a fully configured environment.

```
┌─────────────────────────────────────────────────────────────────────────┐
│ INPUT                                                                    │
│                                                                          │
│   curl -fsSL https://agent-flywheel.com/install?ref=main | \            │
│     bash -s -- --yes --mode vibe                                         │
│                                                                          │
│   Characters: ~80    Tokens: ~20                                         │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ MANIFEST EXPANSION                                                       │
│                                                                          │
│   acfs.manifest.yaml                                                     │
│   ├── 80+ module definitions                                            │
│   ├── 9 execution phases                                                │
│   ├── Dependency graph across modules                                   │
│   ├── Web metadata for each tool                                        │
│   └── Verification commands per module                                  │
│                                                                          │
│   Lines: ~1,500    Size: 75 KB                                           │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ CODE GENERATION                                                          │
│                                                                          │
│   generate.ts (58 KB) transforms manifest into:                          │
│   ├── 11 category install scripts (install_*.sh)                        │
│   ├── doctor_checks.sh (health verification)                            │
│   ├── manifest_index.sh (bash data arrays)                              │
│   └── Web catalog TypeScript files                                      │
│                                                                          │
│   Total generated output: ~5,000+ lines of bash                         │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ ORCHESTRATION                                                            │
│                                                                          │
│   install.sh (5,743 lines) + 50+ library scripts:                        │
│   ├── logging.sh         — output + log capture                         │
│   ├── state.sh           — phase tracking (state.json v3)               │
│   ├── error_tracking.sh  — error context capture                        │
│   ├── security.sh        — HTTPS + checksum verification                │
│   ├── install_helpers.sh — execution context routing                    │
│   ├── agents.sh          — Claude/Codex/Gemini install                  │
│   ├── doctor.sh          — 96 KB health checks                          │
│   ├── update.sh          — 80 KB update orchestration                   │
│   ├── sandbox.sh         — LXD container setup                          │
│   └── 40+ more libraries                                               │
│                                                                          │
│   Total library code: ~300 KB+ across 50+ files                          │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ SYSTEM TRANSFORMATION                                                    │
│                                                                          │
│   Fresh Ubuntu VPS → Agent-Ready Dev Environment                         │
│                                                                          │
│   ├── 60+ packages installed via apt                                    │
│   ├── 7 language runtimes (bun, uv/python, rust, go, ruby, java, php)  │
│   ├── 4 AI coding agents (Claude, Codex, Gemini, Amp)                  │
│   ├── 10 multi-agent coordination tools                                 │
│   ├── Shell environment (zsh + oh-my-zsh + powerlevel10k)              │
│   ├── Cloud tools (vault, wrangler, supabase, vercel)                  │
│   ├── Developer utilities (tmux, lazygit, ripgrep, fzf, gh)           │
│   ├── Configuration files (~20 dotfiles/configs)                        │
│   └── Running services (tmux, dashboard, tailscale)                    │
│                                                                          │
│   Files created/modified: 500+                                           │
│   Total disk footprint: ~2-4 GB                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Memory & Context Flow

How the state manager handles phase tracking, error context, and resumability during a long-running installation.

```mermaid
flowchart TB
    subgraph StateInit["State Initialization"]
        START([install.sh starts]) --> DETECT{state.json<br/>exists?}
        DETECT -->|No| INIT["init_state()<br/>Create empty v3 schema"]
        DETECT -->|Yes| LOAD["state_load()<br/>Parse existing state"]
        LOAD --> VALIDATE{Schema<br/>version = 3?}
        VALIDATE -->|No| MIGRATE["Migrate schema<br/>v1/v2 → v3"]
        VALIDATE -->|Yes| RESUME_CHECK
        MIGRATE --> RESUME_CHECK
        INIT --> FRESH[Start Phase 1]
    end

    subgraph ResumeLogic["Resume Decision"]
        RESUME_CHECK{completed_phases<br/>present?} -->|Yes| SKIP_DONE["Skip completed phases<br/>(installed_check confirms)"]
        RESUME_CHECK -->|No| FRESH
        SKIP_DONE --> RESUME_PHASE["Resume from<br/>current_phase"]
    end

    subgraph PhaseExecution["Phase Execution Loop"]
        RESUME_PHASE --> PHASE_START["state_phase_start(id)<br/>Update current_phase"]
        FRESH --> PHASE_START
        PHASE_START --> STEP["state_step_update(desc)<br/>Track current operation"]
        STEP --> EXEC_CMD["Execute module commands"]

        EXEC_CMD -->|Success| NEXT_MOD{More<br/>modules?}
        NEXT_MOD -->|Yes| STEP
        NEXT_MOD -->|No| PHASE_DONE["state_phase_complete()<br/>Add to completed_phases"]
        PHASE_DONE --> NEXT_PHASE{More<br/>phases?}
        NEXT_PHASE -->|Yes| PHASE_START
        NEXT_PHASE -->|No| COMPLETE([Installation Complete])
    end

    subgraph ErrorRecovery["Error Recovery"]
        EXEC_CMD -->|Failure| CAPTURE["Capture error context:<br/>CURRENT_PHASE<br/>CURRENT_STEP<br/>LAST_ERROR<br/>LAST_ERROR_CODE<br/>LAST_ERROR_OUTPUT<br/>LAST_ERROR_TIME"]
        CAPTURE --> PERSIST["state_save()<br/>Write error to state.json"]
        PERSIST --> LOG_ERR["Log to ~/.acfs/logs/"]
        LOG_ERR --> EXIT_ERR([Exit with error code])
        EXIT_ERR -.->|"User re-runs install.sh"| DETECT
    end

    subgraph UbuntuUpgrade["Multi-Reboot Tracking"]
        PHASE_START -->|Phase requires reboot| UPG_STATE["ubuntu_upgrade: {<br/>  original_version<br/>  target_version<br/>  current_stage<br/>}"]
        UPG_STATE --> REBOOT([System Reboot])
        REBOOT -.->|"System restarts"| DETECT
    end

    subgraph StateSchema["state.json v3 Schema"]
        STATEJSON[("~/.acfs/state.json")]
        STATEJSON --- FIELDS["schema_version: 3<br/>version: 0.6.0<br/>mode: vibe | safe<br/>started_at: ISO timestamp<br/>last_updated: ISO timestamp<br/>completed_phases: [...]<br/>current_phase: string<br/>current_step: string<br/>failed_phase: string | null<br/>failed_error: string | null<br/>skipped_tools: [...]<br/>phase_durations: {id: secs}<br/>ubuntu_upgrade: {...}"]
    end

    PHASE_START --> STATEJSON
    PHASE_DONE --> STATEJSON
    PERSIST --> STATEJSON

    classDef init fill:#e0f2fe,stroke:#0284c7
    classDef resume fill:#dcfce7,stroke:#16a34a
    classDef exec fill:#fef3c7,stroke:#d97706
    classDef error fill:#fee2e2,stroke:#dc2626
    classDef upgrade fill:#f3e8ff,stroke:#9333ea
    classDef state fill:#e0e7ff,stroke:#4f46e5

    class START,DETECT,INIT,LOAD,VALIDATE,MIGRATE init
    class RESUME_CHECK,SKIP_DONE,RESUME_PHASE resume
    class PHASE_START,STEP,EXEC_CMD,NEXT_MOD,PHASE_DONE,NEXT_PHASE,COMPLETE exec
    class CAPTURE,PERSIST,LOG_ERR,EXIT_ERR error
    class UPG_STATE,REBOOT upgrade
    class STATEJSON,FIELDS state
```

### Context Budget Management

| Context Layer | Storage Location | Size Limit | Eviction Strategy |
|---|---|---|---|
| **Phase state** | `~/.acfs/state.json` | ~2 KB | Overwrite on each save |
| **Error context** | Shell variables + state.json | 2,000 chars (stderr) | Truncate LAST_ERROR_OUTPUT |
| **Install logs** | `~/.acfs/logs/install-*.log` | Unbounded (append) | One file per session |
| **Agent memory** | `~/.claude/memory/` | Per-topic JSON files | Manual pruning |
| **Session archive** | `~/.acfs/cass/` | Per-session records | Indexed by date |
| **Message archive** | `.mcp-mail/` in project | Per-thread JSON | Thread-based retention |

---

## 6. Event Timeline

Chronological view of all events emitted during a typical full installation.

```
Time    Event                          Source              State Change
─────── ────────────────────────────── ─────────────────── ──────────────────────────
T+0s    INSTALL_START                  install.sh          mode=vibe, started_at=now
T+1s    CONTRACT_VALIDATE              contract.sh         Checking bash, curl, jq
T+2s    CONTRACT_PASS                  contract.sh         Pre-flight OK
T+3s    AUTOFIX_RUN                    autofix.sh          Patching detected issues
T+5s    STATE_INIT                     state.sh            state.json created (v3)
│
T+6s    PHASE_START: base_system       error_tracking.sh   current_phase=base_system
T+7s    STEP: "Installing curl"        error_tracking.sh   current_step updated
T+8s    INSTALLED_CHECK_PASS: curl     Phase Executor      Skip (already present)
T+9s    STEP: "Installing git"         error_tracking.sh   current_step updated
T+10s   INSTALLED_CHECK_PASS: git      Phase Executor      Skip (already present)
T+15s   STEP: "Installing jq"          error_tracking.sh   current_step updated
T+45s   INSTALL_COMPLETE: base pkgs    Phase Executor      apt-get finished
T+46s   VERIFY_PASS: curl, git, jq     Phase Executor      All verify commands pass
T+47s   PHASE_COMPLETE: base_system    state.sh            completed_phases += base_system
│
T+48s   PHASE_START: user_setup        error_tracking.sh   current_phase=user_setup
T+50s   STEP: "Configure ubuntu user"  error_tracking.sh   Manual/orchestration step
T+55s   PHASE_COMPLETE: user_setup     state.sh            completed_phases += user_setup
│
T+56s   PHASE_START: filesystem        error_tracking.sh   current_phase=filesystem
T+57s   STEP: "Create /data/projects"  error_tracking.sh   mkdir + chown
T+60s   STEP: "Create ~/.acfs"         error_tracking.sh   Config directory
T+65s   PHASE_COMPLETE: filesystem     state.sh            completed_phases += filesystem
│
T+66s   PHASE_START: shell_setup       error_tracking.sh   current_phase=shell_setup
T+70s   SECURITY_VERIFY: oh-my-zsh    security.sh         SHA256 checksum OK
T+90s   STEP: "Install oh-my-zsh"      error_tracking.sh   Verified installer pipe
T+100s  STEP: "Install powerlevel10k"  error_tracking.sh   Git clone + config
T+110s  PHASE_COMPLETE: shell_setup    state.sh            completed_phases += shell_setup
│
T+111s  PHASE_START: languages         error_tracking.sh   current_phase=languages
T+115s  SECURITY_VERIFY: bun           security.sh         SHA256 checksum OK
T+120s  STEP: "Install bun"            error_tracking.sh   curl | bash verified
T+135s  STEP: "Install uv + Python"    error_tracking.sh   Verified installer
T+160s  STEP: "Install rustup"         error_tracking.sh   curl | sh verified
T+190s  STEP: "Install Go"             error_tracking.sh   Binary download
T+210s  STEP: "Install Ruby (rbenv)"   error_tracking.sh   Git clone + build
T+240s  STEP: "Install Java (SDKMAN)"  error_tracking.sh   Verified installer
T+260s  VERIFY_PASS: all runtimes      Phase Executor      bun, python, cargo, go, ruby
T+261s  PHASE_COMPLETE: languages      state.sh            completed_phases += languages
│
T+262s  PHASE_START: agents            error_tracking.sh   current_phase=agents
T+265s  STEP: "Install Claude Code"    error_tracking.sh   bun add -g
T+280s  VERIFY_PASS: claude            agents.sh           claude --version OK
T+285s  STEP: "Install Codex"          error_tracking.sh   bun add -g
T+300s  VERIFY_PASS: codex             agents.sh           codex --version OK
T+305s  STEP: "Install Gemini"         error_tracking.sh   bun add -g
T+315s  VERIFY_PASS: gemini            agents.sh           gemini --version OK
T+316s  PHASE_COMPLETE: agents         state.sh            completed_phases += agents
│
T+317s  PHASE_START: cloud_db          error_tracking.sh   current_phase=cloud_db
T+320s  STEP: "Install Vault"          error_tracking.sh   Binary download + verify
T+340s  STEP: "Install Wrangler"       error_tracking.sh   bun add -g
T+355s  STEP: "Install Supabase CLI"   error_tracking.sh   bun add -g
T+370s  PHASE_COMPLETE: cloud_db       state.sh            completed_phases += cloud_db
│
T+371s  PHASE_START: stack             error_tracking.sh   current_phase=stack
T+375s  STEP: "Install NTM"            error_tracking.sh   Verified installer
T+400s  STEP: "Install MCP Agent Mail" error_tracking.sh   Verified installer
T+420s  STEP: "Install UBS"            error_tracking.sh   Verified installer
T+440s  STEP: "Install CASS"           error_tracking.sh   Verified installer
T+500s  PHASE_COMPLETE: stack          state.sh            completed_phases += stack
│
T+501s  PHASE_START: finalize          error_tracking.sh   current_phase=finalize
T+505s  SERVICE_START: tmux            services-setup.sh   Session created
T+510s  SERVICE_START: dashboard       services-setup.sh   localhost:38080
T+520s  ONBOARD_LAUNCH                 onboard.sh          TUI starts (14 lessons)
T+900s  ONBOARD_COMPLETE               onboard.sh          All lessons done
T+901s  PHASE_COMPLETE: finalize       state.sh            completed_phases += finalize
│
T+902s  INSTALL_COMPLETE               install.sh          Exit 0 — VPS ready
```

### Event Category Summary

| Category | Count | Examples |
|---|---|---|
| Phase transitions | 18 | `PHASE_START`, `PHASE_COMPLETE` (×9 phases) |
| Step updates | 40–60 | `STEP: "Installing X"` per module |
| Security verifications | 10–15 | `SECURITY_VERIFY: tool` per verified installer |
| Installed checks | 80+ | `INSTALLED_CHECK_PASS/FAIL` per module |
| Verify passes | 80+ | `VERIFY_PASS: tool` per module |
| Service starts | 3–5 | `SERVICE_START: tmux, dashboard` |
| Error events | 0–5 | `ERROR: phase/step` (on failure only) |
| **Total events** | **~230–250** | **Per full installation run** |

---

## 7. Estimated Metrics

### Installation Run Metrics

| Metric | Value | Notes |
|---|---|---|
| **Total install time** | 15–30 min | VPS with good bandwidth |
| **Manifest modules** | 80+ | Across 9 phases |
| **Bash lines executed** | ~10,000+ | install.sh + libraries + generated scripts |
| **Library scripts sourced** | 50+ | From `scripts/lib/` |
| **Generated scripts** | 11 | Category installers from manifest |
| **apt packages** | 60+ | Phase 1 base system |
| **Language runtimes** | 7 | bun, python, rust, go, ruby, java, php |
| **AI agents installed** | 4 | Claude, Codex, Gemini, Amp |
| **Coordination tools** | 10 | NTM, MCP Mail, UBS, CASS, etc. |
| **Config files created** | ~20 | Dotfiles, agent configs, shell configs |
| **Network requests** | 50–80 | Package downloads, git clones, apt fetches |
| **SHA256 verifications** | 10–15 | Per verified installer |
| **Disk usage** | 2–4 GB | All tools + runtimes + caches |
| **state.json writes** | ~20 | Phase start/complete + error saves |
| **Log file size** | 500 KB – 2 MB | Per installation session |

### Codebase Metrics

| Metric | Value | Notes |
|---|---|---|
| **install.sh** | 5,743 lines | Main orchestrator |
| **Library scripts** | ~300 KB total | 50+ files in `scripts/lib/` |
| **Manifest** | ~1,500 lines (75 KB) | Single source of truth |
| **Generator** | 58 KB | `generate.ts` (TypeScript) |
| **Web app** | 1,000+ TS lines | Next.js 16 wizard |
| **Onboard TUI** | 50 KB | Compiled shell script |
| **Doctor checks** | 96 KB | Health verification |
| **Update orchestrator** | 80 KB | Update management |
| **Total codebase** | ~1 MB+ | Bash + TypeScript + YAML + Markdown |

### Manifest Generator Throughput

| Input | Output | Ratio |
|---|---|---|
| 1 module definition (~20 lines YAML) | ~50 lines bash + ~30 lines TypeScript | 1:4 |
| 80 modules (1,500 lines YAML) | ~5,000 lines bash + ~2,000 lines TS | 1:4.7 |
| 1 `verified_installer` block | ~15 lines secure bash (checksum + pipe) | 1:5 |
| Full manifest | 11 install scripts + doctor + index + web data | 1 file → 15+ files |

### Agent Coordination Metrics (Post-Install)

| Metric | Value | Notes |
|---|---|---|
| **MCP Mail message size** | ~0.5–2 KB each | JSON with thread_id, body, metadata |
| **File reservation TTL** | 3,600s default | Per-agent file locks |
| **Session archive search** | <1s per query | CASS indexed by agent + date |
| **Agent memory entries** | 10–100 per project | CM topic-based JSON |
| **Concurrent agents** | 2–4 typical | Claude + Codex + Gemini in parallel |

---

## Appendix: Phase Dependency Graph

```mermaid
flowchart LR
    P1[Phase 1<br/>Base System<br/>apt packages] --> P2[Phase 2<br/>User Setup<br/>ubuntu user]
    P2 --> P3[Phase 3<br/>Filesystem<br/>/data/projects]
    P3 --> P4[Phase 4<br/>Shell Setup<br/>zsh + p10k]
    P4 --> P5[Phase 5<br/>Languages<br/>7 runtimes]
    P5 --> P6[Phase 6<br/>Agents<br/>Claude/Codex/Gemini]
    P5 --> P7[Phase 7<br/>Cloud & DB<br/>vault/wrangler]
    P6 --> P8[Phase 8<br/>Stack<br/>10 coordination tools]
    P7 --> P8
    P8 --> P9[Phase 9<br/>Finalize<br/>services + onboard]

    classDef base fill:#dbeafe,stroke:#2563eb
    classDef mid fill:#fef3c7,stroke:#d97706
    classDef agent fill:#dcfce7,stroke:#16a34a
    classDef final fill:#f3e8ff,stroke:#9333ea

    class P1,P2,P3 base
    class P4,P5 mid
    class P6,P7,P8 agent
    class P9 final
```
