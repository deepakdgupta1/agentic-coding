# Fork Workflow Strategy: "The Integration Branch Pattern"

This guide outlines the optimal workflow for maintaining a long-lived fork that consumes upstream updates while developing local features.

## The Goal
1.  **Consume Upstream**: Get daily updates from `Dicklesworthstone/agentic_coding_flywheel_setup`.
2.  **Develop Locally**: Build new features in isolation.
3.  **Integrate**: Combine both sources into a stable deployment branch.

## The "Integration Branch" Pattern

We use a specific branching strategy to keep streams of work clean.

### Branches

| Branch Name | Role | Source of Truth |
| :--- | :--- | :--- |
| `main` | **Pure Upstream Mirror** | ONLY upstream code. Never commit here directly. |
| `feature/*` | **Your Work** | Your isolated feature development. |
| `local-desktop-installation-support` | **Integration / Deployment** | The "Production" branch for your local install. Contains Upstream + Your Features. |

### Visual Data Flow

```mermaid
graph TD
    subgraph Upstream Repo
        U[Upstream / main]
    end

    subgraph Your Fork
        M[main<br/>(Pure Copy)]
        F1[feature/my-cool-config]
        F2[feature/custom-scripts]
        I[local-desktop-installation-support<br/>(Integration Branch)]
    end

    %% Flows
    U -->|Action: Daily Sync| I
    F1 -->|PR: Merge| I
    F2 -->|PR: Merge| I

    style I fill:#d4edda,stroke:#28a745,stroke-width:2px
    style U fill:#cce5ff,stroke:#004085,stroke-width:2px
```

## Daily Protocol

### 1. The Automated Morning Sync
Your GitHub Action `upstream-sync.yml` runs daily.
-   It pulls `upstream/main`.
-   It attempts to merge into `local-desktop-installation-support`.
-   **If Clean**: It pushes automatically. You wake up to a fresh, up-to-date repo.
-   **If Conflict**: It opens a PR with conflict markers. You must resolve it (see [Upstream Sync Guide](./upstream-sync.md)).
-   **Token Requirement**: Configure `UPSTREAM_SYNC_TOKEN` so mirror pushes can update `.github/workflows/*` when upstream changes those files.

### 1.5 CI Branch Alignment
`Installer CI` should run on `local-desktop-installation-support` (and PRs targeting it), because that is the deployment/integration branch.

-   Keep `main` as an upstream mirror branch.
-   Use CI on `local-desktop-installation-support` to validate what actually lands on your machine.

### 2. Developing a New Feature (The "Right Way")

**NEVER** work directly on `local-desktop-installation-support`. Always use a feature branch.

#### Step 1: Start Fresh
Always branch off the latest integration branch.
```bash
git checkout local-desktop-installation-support
git pull origin local-desktop-installation-support
git checkout -b feature/my-new-idea
```

#### Step 2: Hack & Commit
Work as usual.
```bash
# code code code
git add .
git commit -m "Add my new idea"
```

#### Step 3: Merge back to Integration
When ready, merge your feature into the integration branch.
```bash
git checkout local-desktop-installation-support
git merge feature/my-new-idea
git push origin local-desktop-installation-support
```
*Tip: If you want to use PRs for your own features to run tests, that's even better! Open a PR from `feature/my-new-idea` -> `local-desktop-installation-support`.*

### 3. Handling Upstream "Gotchas"

Sometimes upstream changes a file you also changed.

1.  **The Action fails to merge cleanly.**
2.  **You get a Notification.**
3.  **You Open the PR** created by the action.
4.  **You Resolve Conflicts** (locally or in UI) to decide: "Do I keep my custom config, or take their update?"

## Summary Rules

1.  **Don't touch `main`**. Let the sync action handle upstream data.
2.  **Don't commit to `local-desktop-installation-support` directly** for big work. Use feature branches.
3.  **Treat `local-desktop-installation-support` as your "Personal Production"**. If it's in there, it's live on your machine.
