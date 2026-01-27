# rch - Remote Compilation Helper

Transparent build offloading for AI coding agents with automatic fallback.

## What It Does

`rch` (Remote Compilation Helper) offloads expensive compilation tasks to remote workers:
- Rust/Cargo builds
- Go compilation
- Any CPU-intensive build process

This keeps local machines responsive during AI coding sessions while leveraging more powerful remote build servers.

## Installation Verification

```bash
# Check rch is installed
rch --version

# Or check help
rch --help
```

## Basic Usage

### Check Status

```bash
# Show current configuration and worker status
rch status

# Check if remote workers are available
rch workers
```

### Configure Remote Workers

```bash
# Add a remote build worker
rch worker add worker1.example.com

# Set default worker
rch config set default-worker worker1.example.com
```

### Build Commands

```bash
# Offload cargo build
rch cargo build --release

# Offload go build
rch go build ./...

# Run any command remotely
rch exec make -j8
```

## Common Workflows

### Rust Development

```bash
# Check then build remotely
rch cargo check
rch cargo build --release

# Run tests remotely
rch cargo test
```

### Go Development

```bash
# Build Go project remotely
rch go build -o bin/myapp ./cmd/myapp

# Run tests
rch go test ./...
```

### Automatic Fallback

If remote workers are unavailable, rch falls back to local execution:

```bash
# This works even without remote workers
rch cargo build  # Falls back to local if needed
```

## Configuration

Configuration is stored in `~/.config/rch/config.toml`:

```toml
[default]
worker = "worker1.example.com"
fallback = "local"
timeout = 300

[workers.worker1]
host = "worker1.example.com"
port = 22
user = "builder"
```

## Troubleshooting

### "No workers available"

Check worker connectivity:

```bash
# Test SSH connection to worker
ssh builder@worker1.example.com echo "Connected"

# Check worker status
rch workers --verbose
```

### Build Times Out

Increase timeout for large builds:

```bash
rch --timeout 600 cargo build --release
```

### "rch: command not found"

Verify installation:

```bash
# Check installation path
which rch
ls -la ~/.cargo/bin/rch

# Install via cargo if missing
cargo install rch
```

### Local Fallback Not Working

Check fallback configuration:

```bash
# Verify config
rch config show

# Ensure local toolchain is available
cargo --version
go version
```

## Integration with AI Agents

Agents can use rch for:
1. Long-running builds that would block the agent
2. Release builds that benefit from more CPU cores
3. Cross-compilation on appropriate worker machines

Best practices:
- Use rch for release builds (`--release`)
- Use local for quick debug builds
- Monitor worker availability before starting builds

## Related Tools

- `cargo` - Rust build system (wrapped by rch)
- `go` - Go toolchain (wrapped by rch)
- `pt` - Process triage for managing stuck builds
