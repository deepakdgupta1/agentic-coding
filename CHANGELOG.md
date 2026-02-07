# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **BREAKING**: `git_safety_guard` replaced by **DCG (Destructive Command Guard)**
  - The legacy `git_safety_guard.py` hook has been fully removed
  - DCG is now the only supported command safety mechanism
  - Automatic cleanup of legacy files during `acfs update`

### Migration: git_safety_guard → DCG

If you installed ACFS before January 11, 2026, your installation may have legacy `git_safety_guard` files.

**Symptoms of old installation:**
- `acfs doctor` shows "Git safety guard" warning
- Files exist at `~/.acfs/claude/hooks/git_safety_guard.py` or `~/.claude/hooks/`

**Migration steps:**
1. Run `acfs update` - this automatically removes legacy files
2. Install DCG: `dcg install`
3. Verify: `acfs doctor` should show only DCG check (no git_safety_guard warnings)

**Why DCG?**
- Built in Rust for sub-millisecond latency (vs Python startup overhead)
- Modular pack system for extensibility
- Dedicated repository and maintenance at [dcg](https://github.com/Dicklesworthstone/destructive_command_guard)

### Added

- **New Flywheel Tools**:
  - **beads_rust (br)** - Rust port of issue tracker, replaces golang beads
    - `bd` alias maintained for backward compatibility
    - Companion **bv** (beads_viewer) for graph-aware task triage
  - **meta_skill (ms)** - Knowledge management and skill distribution
  - **remote_compilation_helper (rch)** - Build acceleration for agent swarms
  - **wezterm_automata (wa)** - Multi-agent orchestration via WezTerm
  - **brenner_bot** - Research session CLI and orchestration

- **Utility Tools** (9 new):
  - **toon_rust (tru)** - Token-optimized notation format
  - **rust_proxy** - Transparent proxy routing
  - **rano** - Network observer for AI CLIs
  - **xf** - X (Twitter) archive search
  - **markdown_web_browser (mdwb)** - Website to Markdown converter
  - **process_triage (pt)** - Zombie process detector
  - **aadc** - ASCII diagram corrector
  - **source_to_prompt_tui (s2p)** - Code to LLM prompt generator
  - **coding_agent_usage_tracker (caut)** - LLM provider usage tracker

- **E2E Testing**: New comprehensive test suite at `tests/e2e/test_new_tools_e2e.sh`
  - Verifies all 16 new tools install correctly
  - Integration tests for acfs doctor, bd alias, flywheel.ts
  - JSON output for CI integration

- **Automatic Ubuntu Upgrade**: The installer now automatically upgrades Ubuntu to 25.10 before running the main ACFS installation
  - Detects current Ubuntu version and calculates sequential upgrade path
  - Handles reboots automatically via systemd resume service
  - Supports upgrade chains: 22.04 → 24.04 → 25.04 → 25.10 (EOL interim releases like 24.10 may be skipped)
  - Creates MOTD banners to show progress to reconnecting users
  - Includes preflight checks for disk space, network, and apt state
  - Provides graceful degradation if upgrade fails but system is functional
  - Skip with `--skip-ubuntu-upgrade` flag
  - Full documentation at `docs/ubuntu-upgrade.md`
- Error boundary for lesson rendering
- Accessibility improvements (prefers-reduced-motion support)

### Fixed

- Onboard lesson lock release when jq fails
- IPv6 zone ID rejection in VPS IP validation
- Security validations in manifest category names
- Lesson progression and shell config improvements
- Various bug fixes from code review

### Changed

- Consolidated duplicate cycle detection implementations
- Split tool page into server and client components

## [0.4.0] - 2026-01-08

### Added

- **DCG (Destructive Command Guard)** added to flywheel stack
- **RU (Repo Updater)** added to flywheel stack
- **GIIL (Get Image from iCloud Link)** added to flywheel stack
- **CSCTF (Chat-to-file converter)** added to flywheel stack

### Fixed

- Prevented test framework pollution of `/data/projects`

## [0.3.0] - 2026-01-07

### Added

- **Interactive TUI wizard** for `acfs newproj` command (`--interactive` flag)
  - 9 wizard screens with ASCII art UI
  - Tech stack detection module
  - AGENTS.md generator with tech-stack-aware sections
- **Bats-core unit testing framework**
- Detailed logging infrastructure for newproj
- `.ubsignore` template for UBS bug scanner
- E2E test suite for newproj TUI wizard
- TUI wizard design documentation

### Fixed

- Security: Remove command injection vulnerability in `validate_directory`
- Numerous TUI display bugs (ASCII alignment, file tree rendering, gitignore handling)
- Claude auth and PostgreSQL role checks in doctor

## [0.2.0] - 2026-01-06

### Added

- **Comprehensive README documentation**:
  - Validation and test harness details
  - Website components and provider guides
  - Learning Hub documentation
  - CI/CD automation details
  - Generator architecture
- Additional Oh My Zsh plugins: python, pip, tmux, tmuxinator, systemd, rsync
- Comprehensive GA4 acquisition tracking and diagnostics

### Fixed

- Agents: handle jq alternative operator treating false as falsy
- Agents: correct heredoc and file ownership bugs in Gemini config
- Agents: configure Gemini CLI for tmux compatibility
- E2E: resolve strict mode and flaky navigation test failures
- CI: resolve YAML lint, shellcheck, and SSH key TTY issues

### Changed

- Refactored CASS robot wrapper code (removed obsolete code)

## [0.1.0] - 2026-01-03

### Added

- Initial release of ACFS (Agentic Coding Flywheel Setup)
- One-liner installer for Ubuntu VPS environments
- Web wizard at agent-flywheel.com for beginners
- Full Dicklesworthstone stack integration (8 tools)
- Three AI coding agents: Claude Code, Codex CLI, Gemini CLI
- Manifest-driven tool definitions
- Checkpointed, idempotent installation
- Interactive onboarding TUI
