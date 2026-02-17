# Upstream Sync Guide

This guide explains how to use and configure the Upstream Sync workflow, which keeps your fork up-to-date with the upstream repository (`Dicklesworthstone/agentic_coding_flywheel_setup`).

## Overview
For a high-level strategy on how to manage your fork with this workflow, please read the **[Fork Workflow Strategy](./fork-workflow-strategy.md)** guide first.

A GitHub Action (`.github/workflows/upstream-sync.yml`) automatically syncs changes from upstream to your fork on a daily basis.

## Components
- **Workflow**: `.github/workflows/upstream-sync.yml`
- **Script**: `scripts/analyze-conflicts.ts`
- **Target Branch**: `local-desktop-installation-support`

## Workflow Logic
1.  **Daily Trigger**: Runs at 00:00 UTC.
2.  **Sync**: Merges `upstream/main` into a branch named `upstream-sync`.
3.  **Conflict Handling**:
    - **Clean Merge**: Automatically pushes the updates to your target branch (`local-desktop-installation-support`). No PR is created.
    - **Conflict**: Commits files *with conflict markers* to a new branch and creates a PR so you can resolve them.
4.  **AI Analysis**: If conflicts exist AND `OPENAI_API_KEY` is set in repository secrets, an AI suggestion is posted as a comment on the PR.

## Configuration: Setting up the API Key
To enable AI conflict analysis, you must securely add your OpenAI API Key to the repository secrets.

1.  **Go to Settings**: Navigate to your GitHub repository page and click on the **Settings** tab.
2.  **Access Secrets**: In the left sidebar, click on **Secrets and variables**, then select **Actions**.
3.  **Create New Secret**: Click the green **New repository secret** button.
4.  **Add Key**:
    - **Name**: `OPENAI_API_KEY`
    - **Secret**: Paste your OpenAI API Key (starts with `sk-...`).
    - Click **Add secret**.

**Important Notes:**
- **Security**: The key is encrypted and never exposed in logs.
- **Scope**: This key is only available to the Action runners.

## Resolving Conflicts

### Option A: In the Browser (GitHub UI)
1.  Open the PR.
2.  Click **Files changed**.
3.  Find the files with `<<<<<<< HEAD` markers.
4.  Edit the file to resolve.
5.  Commit the changes.

### Option B: Locally in VS Code (Recommended)
You can use VS Code's powerful conflict resolution tools.

1.  **Fetch changes**:
    ```bash
    git fetch origin
    git checkout upstream-sync
    ```
2.  **Open files**: VS Code will automatically highlight the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).
3.  **Resolve**: Use the "Accept Current Change" | "Accept Incoming Change" buttons that appear above the conflict.
    > **Note**: Since the markers were committed to the file, VS Code treats them as text but still provides the helpful UI!
4.  **Push**:
    ```bash
    git add .
    git commit -m "Resolve conflicts"
    git push origin upstream-sync
    ```

## Manual Trigger
To run the sync manually:
1.  Go to the **Actions** tab in your GitHub repository.
2.  Select **Upstream Sync** from the left sidebar.
3.  Click **Run workflow**.
4.  Select the branch and click **Run workflow**.
