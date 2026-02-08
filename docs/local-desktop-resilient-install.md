# ACFS Local Desktop: Resilient Install & Uninstall Checklist

This is a living, experience-driven checklist for running ACFS in an LXD sandbox on a desktop.
Keep it updated as new failure modes are discovered.

## Goals

- Provide a reliable, repeatable setup flow
- Auto-repair common failure modes before they surface
- Capture known failure modes and their mitigations

- LXD container name (default: `acfs-local`)
- Ubuntu image (default: `ubuntu:24.04`)
- Dashboard port (default: `38080`)
- Storage driver choice:
  - `dir` (default) or
  - ZFS pool (recommended for performance)
- Virtualization Host (for macOS):
  - Multipass VM (Ubuntu 24.04 host)

## Environment Variables (supported)

- `ACFS_LXD_ZFS_DEVICE`: block device for ZFS pool creation (optional, destructive)
- `ACFS_LXD_ZFS_POOL`: ZFS pool name (default: `lxd_pool`)
- `ACFS_LXD_STORAGE_DRIVER`: storage driver if not using ZFS (default: `dir`)
- `ACFS_LXD_STORAGE_POOL`: storage pool name to use for the default profile root device
- `ACFS_DASHBOARD_PORT`: host port for the dashboard proxy (default: `38080`)
- `ACFS_WORKSPACE_HOST`: host path for the workspace mount (default: `~/acfs-workspace`)

## Universal Installer Flow

The ACFS installer (`install.sh`) now features a **Universal Selection Menu** that guides you through the process based on your current OS and target environment.

### 1. VPS (Remote Ubuntu)
The standard installation for dedicated servers or cloud instances. Installs ACFS directly on the host.

### 2. macOS Local (Multipass)
For MacBook users. This flow:
1.  Verifies/Prompts for **Multipass** installation.
2.  Launches a lightweight Ubuntu 24.04 VM (`acfs-host`).
3.  Mounts your host workspace folder to the VM.
4.  Initializes an ACFS sandbox (LXD) inside the VM.

### 3. Ubuntu Desktop Local (LXD)
For Linux users. This flow:
1.  Verifies/Configures **LXD** on your host.
2.  Prompts for an optional **ZFS device** path for high-performance storage.
3.  Launches an ACFS sandbox container.

---

## Usage (All Platforms)

```bash
# Start the interactive installer
curl -fsSL "https://agent-flywheel.com/install" | bash
```

## Idempotency Audit Mode (Dry-Run)

```bash
# macOS (Multipass host checks + in-VM audit when available)
./install.sh --macos --idempotency-audit

# Ubuntu Desktop Local (LXD host checks + in-VM checks)
./install.sh --local --idempotency-audit

# Direct local audit (Ubuntu host)
acfs-local audit
```

## Resilient Install Flow (with checks and fallbacks)

0. macOS host (Multipass) readiness
   - Check: `multipass wait-ready` succeeds (daemon ready).
   - If not ready: retry with backoff; prompt to restart Multipass if it remains unavailable.
   - Check: VM exists; if stopped/suspended, `multipass start <vm>`.
   - Check: VM reachable via `multipass exec <vm> -- true`.
   - If unreachable: `multipass restart <vm>` and retry.
   - Check: workspace mount exists.
   - If mount fails: `multipass umount <vm>:acfs-workspace` then re-mount.
   - If still failing: warn and proceed without host workspace sharing.

1. LXD installed and initialized
   - Check: `lxc version` and `lxc info` succeed.
   - If missing: install `lxd` (snap) and initialize (`lxd init`).
   - If permission denied: ensure user is in `lxd` group and refresh group.

2. LXD remote availability
   - Check: `lxc remote list` includes `ubuntu`.
   - If missing: add `ubuntu` simplestreams remote.

3. Storage pool selection and existence
   - Check: default storage pool exists (or `ACFS_LXD_STORAGE_POOL` if set).
   - If missing: create a pool using the selected driver (`dir` or ZFS-backed).

4. ZFS device readiness (only if using ZFS)
   - Check: device exists, is a block device, and is empty (no filesystem / no ZFS signature).
   - If not empty: stop and choose a different device or explicitly wipe it.
   - Check: `zpool` command exists.
   - If missing: install `zfsutils-linux`.

5. Create or validate ZFS pool (only if using ZFS)
   - Check: `zpool list` shows the pool as healthy.
   - If missing: create it using `ACFS_LXD_ZFS_DEVICE`.
   - If unhealthy: investigate kernel/zfs module status and device conflicts.

6. LXD storage pool health
   - Check: `lxc storage show default` reports:
     - `driver: zfs` when using ZFS
     - `status: Available`
   - If `Unavailable` and ZFS:
     - Verify the ZFS pool exists and matches LXD’s `source`.
     - Recreate the pool or update LXD storage config.

7. Default profile root disk device
   - Check: `lxc profile device show default root` exists.
   - If missing: add `root` device and point at the selected pool.

8. LXD network readiness
   - Check: `lxc network show lxdbr0` exists and has NAT enabled.
   - If missing: create bridge and enable NAT.

9. Dashboard port availability
   - Check: `38080` is free (or the value of `ACFS_DASHBOARD_PORT`).
   - If in use: select the next free port and update the proxy device.

10. Workspace directory readiness
   - Check: host workspace path exists and is writable.
   - If path is a file: pick a safe fallback directory.
   - If permissions are wrong: attempt `chown`/`chmod`.

11. Create the ACFS container
   - Check: `lxc info acfs-local` shows `Status: RUNNING`.
   - If launch fails: re-check storage pool availability and profile config.

12. Container egress connectivity
   - Check inside container: default route exists and outbound TCP works.
   - If no route or no egress:
     - Add a macvlan NIC attached to the host’s default interface.
     - Apply a netplan override to prefer the macvlan route.
   - If still blocked: inspect host firewall/NAT.

13. Run ACFS installer (local mode)
   - Check: preflight passes (network, apt, checksums).
   - If checksum mismatch: refresh `checksums.yaml` and retry.

14. Onboard assets
   - Check: `onboard` exists in `~/.local/bin`.
   - If missing: verify `packages/onboard` assets were transferred and finalize steps executed.

15. Agent Mail
   - Check: `mcp-agent-mail` exists; `am` starts a session.
   - If installer lock is stuck:
     - Identify tmux server holding the lock.
     - Close lock FDs before tmux spawn (fixed in install script).

16. Smoke test
   - Check: 8/8 critical checks pass.
   - If any fail: re-run the specific phase or manually repair missing artifacts.

## Idempotency Matrix

### macOS host (Multipass)
| Step | Idempotent check | No-op when | Repair action |
| --- | --- | --- | --- |
| Multipass daemon | `multipass wait-ready` | Daemon ready | Retry wait; prompt to restart Multipass if still unavailable |
| VM state | `multipass info <vm>` | State is `Running` | `multipass start` if stopped/suspended; `multipass restart` if unresponsive |
| VM reachability | `multipass exec <vm> -- true` | Exec succeeds | Restart VM, then retry exec |
| Workspace mount | Mountpoint at `/home/ubuntu/acfs-workspace` | Mount present | `multipass umount` then re-mount; warn and continue if still failing |

### Ubuntu Desktop host (LXD)
| Step | Idempotent check | No-op when | Repair action |
| --- | --- | --- | --- |
| LXD availability | `lxc info` | LXD responds | Install/initialize LXD, refresh group permissions |
| Storage pool | `lxc storage list` / `lxc storage show` | Pool exists and available | Create pool or repair ZFS source |
| Default profile root | `lxc profile device show default root` | Root device configured | Add root device pointing at chosen pool |
| Workspace dir | Host path exists + writable | Path valid | Create fallback path; fix permissions |
| Profile devices | `lxc profile device show acfs-local-profile` | Devices match desired state | Update workspace, network, and dashboard proxy devices |
| Container ready | `lxc info acfs-local` + exec | Running and responsive | Start/restart container; re-apply workspace device |
| Container egress | Default route + outbound TCP | Egress works | Add macvlan NIC and apply netplan override |

### In-VM `--local` (inside LXD container)
| Step | Idempotent check | No-op when | Repair action |
| --- | --- | --- | --- |
| Install already done | `~/.local/bin/acfs`, `/usr/local/bin/acfs`, `~/.acfs/scripts/lib/dashboard.sh`, `~/.local/bin/onboard` | All present | Re-run installer if any missing |
| Repo transfer | `tar` pipe to `/tmp` | Transfer succeeds | Retry transfer; ensure container ready |
| Bootstrap assets | `/tmp/scripts/acfs-global` and `/tmp/packages/onboard/onboard.sh` | Both present | Re-transfer and re-validate |
| Installer run | `install.sh --local` | Install succeeds | Retry once after network repair |

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

- **Missing root disk device**
  - Cause: default LXD profile lacks `root` disk.
  - Fix: add a `root` disk pointing at the selected pool.

- **Dashboard port already in use**
  - Cause: `ACFS_DASHBOARD_PORT` occupied by another service.
  - Fix: auto-select next free port and update proxy device.

- **Workspace path is not a directory or is not writable**
  - Cause: file at the workspace path or permissions mismatch.
  - Fix: choose a fallback directory and repair permissions.

- **Ubuntu remote missing**
  - Cause: LXD remotes were customized.
  - Fix: add the `ubuntu` simplestreams remote.

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

- **Multipass daemon not ready**
  - Cause: Multipass service not ready at launch.
  - Fix: use `multipass wait-ready` with retries; restart Multipass if it remains unavailable.

- **Multipass VM unreachable**
  - Cause: VM boot stalled or stale network state.
  - Fix: `multipass restart <vm>` and retry `multipass exec`.

- **Multipass workspace mount failed**
  - Cause: stale mount metadata or path conflicts.
  - Fix: `multipass umount <vm>:acfs-workspace`, re-mount, and verify in VM.

## How to Keep This Document Current

- After each install or uninstall incident:
  - Add the failure mode + root cause.
  - Add the detection check.
  - Add the remediation steps.
- Prefer explicit checks that can be automated in the installer.
- Avoid destructive actions unless the user explicitly confirms them.
