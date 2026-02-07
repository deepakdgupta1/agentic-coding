# ACFS Local Desktop: Resilient Install & Uninstall Checklist

This is a living, experience-driven checklist for running ACFS in an LXD sandbox on a desktop.
Keep it updated as new failure modes are discovered.

## Goals

- Provide a reliable, repeatable setup flow
- Fail fast with actionable diagnostics
- Capture known failure modes and their mitigations

## Required Inputs (decide up front)

- LXD container name (default: `acfs-local`)
- Ubuntu image (default: `ubuntu:24.04`)
- Dashboard port (default: `38080`)
- Storage driver choice:
  - `dir` (default) or
  - ZFS pool (recommended for performance)

## Environment Variables (supported)

- `ACFS_LXD_ZFS_DEVICE`: block device for ZFS pool creation (optional, destructive)
- `ACFS_LXD_ZFS_POOL`: ZFS pool name (default: `lxd_pool`)
- `ACFS_LXD_STORAGE_DRIVER`: storage driver if not using ZFS (default: `dir`)

## Resilient Install Flow (with checks and fallbacks)

1. LXD installed and initialized
   - Check: `lxc version` and `lxc info` succeed.
   - If missing: install `lxd` (snap) and initialize (`lxd init`).
   - If permission denied: ensure user is in `lxd` group and refresh group.

2. ZFS device readiness (only if using ZFS)
   - Check: device exists, is a block device, and is empty (no filesystem / no ZFS signature).
   - If not empty: stop and choose a different device or explicitly wipe it.
   - Check: `zpool` command exists.
   - If missing: install `zfsutils-linux`.

3. Create or validate ZFS pool (only if using ZFS)
   - Check: `zpool list` shows the pool as healthy.
   - If missing: create it using `ACFS_LXD_ZFS_DEVICE`.
   - If unhealthy: investigate kernel/zfs module status and device conflicts.

4. LXD storage pool health
   - Check: `lxc storage show default` reports:
     - `driver: zfs` when using ZFS
     - `status: Available`
   - If `Unavailable` and ZFS:
     - Verify the ZFS pool exists and matches LXD’s `source`.
     - Recreate the pool or update LXD storage config.

5. LXD network readiness
   - Check: `lxc network show lxdbr0` exists and has NAT enabled.
   - If missing: create bridge and enable NAT.

6. Create the ACFS container
   - Check: `lxc info acfs-local` shows `Status: RUNNING`.
   - If launch fails: re-check storage pool availability and profile config.

7. Container egress connectivity
   - Check inside container: `curl -I https://github.com`.
   - If DNS works but outbound fails:
     - Provide a macvlan fallback NIC attached to the host’s main interface.
     - Ensure default route favors macvlan.
   - If still blocked: inspect host firewall/NAT.

8. Run ACFS installer (local mode)
   - Check: preflight passes (network, apt, checksums).
   - If checksum mismatch: refresh `checksums.yaml` and retry.

9. Onboard assets
   - Check: `onboard` exists in `~/.local/bin`.
   - If missing: verify `packages/onboard` assets were transferred and finalize steps executed.

10. Agent Mail
   - Check: `mcp-agent-mail` exists; `am` starts a session.
   - If installer lock is stuck:
     - Identify tmux server holding the lock.
     - Close lock FDs before tmux spawn (fixed in install script).

11. Smoke test
   - Check: 8/8 critical checks pass.
   - If any fail: re-run the specific phase or manually repair missing artifacts.

## Resilient Uninstall Flow (sandbox only)

1. Confirm container exists
   - Check: `lxc list` shows the container.

2. Stop the container
   - Check: `lxc info` shows `Status: STOPPED`.

3. Remove the container and profile (if you want a clean reinstall)
   - Check: `lxc list` no longer shows it.
   - Note: preserve the workspace directory if desired.

4. If using ZFS
   - Decide whether to keep or destroy the ZFS pool.
   - If destroying, be explicit and confirm device ownership.

## Known Failure Modes and Fixes

- **LXD storage pool unavailable (ZFS)**
  - Cause: pool name exists in LXD config but ZFS pool missing.
  - Fix: create the ZFS pool or update the LXD storage pool source.

- **Container has DNS but no outbound network**
  - Cause: NAT/bridge mismatch or firewall.
  - Fix: add macvlan NIC and prefer its default route.

- **Checksum mismatch for installer scripts**
  - Cause: upstream installer changed.
  - Fix: refresh `checksums.yaml` and re-run.

- **Installer lock held by tmux server**
  - Cause: tmux inherits installer lock FD.
  - Fix: close lock FDs before spawning tmux (implemented).

- **Onboard missing**
  - Cause: `packages/onboard` not transferred in local mode.
  - Fix: include `packages/onboard` in the transfer (implemented).

## How to Keep This Document Current

- After each install or uninstall incident:
  - Add the failure mode + root cause.
  - Add the detection check.
  - Add the remediation steps.
- Prefer explicit checks that can be automated in the installer.
- Avoid destructive actions unless the user explicitly confirms them.

