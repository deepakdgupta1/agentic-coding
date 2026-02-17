# Pinned Reference Installs

This document explains how to use pinned references for reproducible ACFS installations.

## Overview

By default, the ACFS installer fetches scripts from the `main` branch. This means you always get the latest version, but installations done at different times may produce different results.

For production environments or when you need consistent installs across multiple machines, you can "pin" to a specific version.

## How Pinning Works

Set the `ACFS_REF` environment variable before running the installer:

```bash
# Pin to a tagged release (recommended for production)
ACFS_REF=v0.6.0 curl -fsSL "https://raw.githubusercontent.com/deepakdgupta1/agentic-coding/v0.6.0/install.sh" | bash -s -- --yes --mode vibe

# Pin to a specific commit SHA (maximum reproducibility)
ACFS_REF=abc1234 curl -fsSL "https://raw.githubusercontent.com/deepakdgupta1/agentic-coding/abc1234/install.sh" | bash -s -- --yes --mode vibe
```

## When to Use Pinning

### Use Pinned References When:

1. **Production Deployments** - Ensure all servers get identical installations
2. **Team Environments** - Keep everyone on the same tool versions
3. **CI/CD Pipelines** - Deterministic builds and tests
4. **Auditing/Compliance** - Document exactly what was installed

### Use Main Branch (Default) When:

1. **Development/Experimentation** - Want latest features and fixes
2. **Single Machine Setup** - One-off personal environment
3. **Following Tutorials** - Using latest documentation

## Tradeoffs

| Aspect | Pinned Ref | Main Branch |
|--------|------------|-------------|
| **Reproducibility** | Exact same install every time | May vary between installs |
| **Latest Fixes** | Only gets fixes in that version | Always gets latest fixes |
| **Security Patches** | Must manually update | Automatic on re-install |
| **Tool Versions** | Frozen at pin time | May get newer tool versions |
| **Checksums** | Stable, verified | May change with upstream |

## Using the Wizard

The [ACFS Wizard](https://agent-flywheel.com/wizard/run-installer) includes a "Pin to specific version" toggle:

1. Enable the toggle
2. Enter a tag (e.g., `v0.6.0`) or commit SHA
3. The generated command includes `ACFS_REF` automatically

## Installer Flags

When using pinned refs, you can also use:

```bash
# Use --pin-ref flag instead of ACFS_REF environment variable
curl -fsSL ".../install.sh" | bash -s -- --yes --mode vibe --pin-ref v0.6.0

# Fetch checksums from a different ref (advanced)
ACFS_CHECKSUMS_REF=main ACFS_REF=v0.6.0 curl ... | bash ...
```

## Finding Version Tags

View available releases:

```bash
# List all tags
curl -s "https://api.github.com/repos/deepakdgupta1/agentic-coding/tags" | jq -r '.[].name'

# Or visit: https://github.com/deepakdgupta1/agentic-coding/releases
```

## Verifying Your Installation

After installation, check which version is installed:

```bash
cat ~/.acfs/VERSION
# Outputs: 0.6.0

# Check the ref used (if recorded)
cat ~/.acfs/INSTALL_REF 2>/dev/null || echo "main (default)"
```

## Updating Pinned Installations

To update a pinned installation:

```bash
# Option 1: Re-run with new pin
ACFS_REF=v0.7.0 curl ... | bash ...

# Option 2: Use acfs update (updates to main)
acfs update

# Option 3: Uninstall and reinstall
rm -rf ~/.acfs && ACFS_REF=v0.7.0 curl ... | bash ...
```

## Best Practices

1. **Document Your Pin** - Record the exact ref used in your deployment docs
2. **Test Before Production** - Try the pinned version on a test machine first
3. **Monitor for Security Updates** - Subscribe to release notifications
4. **Use Tags Over Commits** - Tags are more readable and documented
5. **Keep a Rollback Plan** - Know how to restore if an update breaks things
