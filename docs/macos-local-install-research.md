# macOS Local Install Resilience Research (Multipass + LXD)

Date: 2026-02-07

Goal: Identify official guidance for Multipass and LXD commands needed for readiness checks and safe auto-remediation in the macOS local install flow.

## Sources (Primary)
- Multipass CLI reference (command list, including `list`, `start`, `stop`, `restart`, `mount`, `umount`, `transfer`, `wait-ready`).  
  https://documentation.ubuntu.com/multipass/latest/reference/command-line-interface/
- Multipass `wait-ready` reference.  
  https://documentation.ubuntu.com/multipass/latest/reference/command-line-interface/wait-ready/
- Multipass `start` reference (allowed states and behavior).  
  https://documentation.ubuntu.com/multipass/en/latest/reference/command-line-interface/start/
- Multipass `stop` reference (allowed states, `--force`).  
  https://documentation.ubuntu.com/multipass/latest/reference/command-line-interface/stop/
- Multipass `restart` reference (allowed states).  
  https://documentation.ubuntu.com/multipass/en/latest/reference/command-line-interface/restart
- Multipass `umount` reference.  
  https://documentation.ubuntu.com/multipass/en/latest/reference/command-line-interface/umount/
- Multipass “Share data with an instance” (mount/transfer behavior).  
  https://documentation.ubuntu.com/multipass/en/latest/how-to-guides/manage-instances/share-data-with-an-instance/
- LXD `lxd init --preseed` reference (non-interactive init).  
  https://documentation.ubuntu.com/lxd/stable-4.0/preseed/
- LXD `lxc show` / `lxc info` reference (state vs config inspection).  
  https://documentation.ubuntu.com/lxd/latest/explanation/lxc_show_info/
- LXD `lxc launch` reference (create + start instance).  
  https://documentation.ubuntu.com/lxd/latest/reference/manpages/lxc/launch/

## Key Findings
1. `multipass wait-ready` blocks until the daemon is ready and is explicitly intended for automation to avoid transient “daemon not ready” failures. Use it before `list`, `launch`, or `exec` in scripts.  
   Source: Multipass `wait-ready` reference.

2. `multipass start` only works for instances in `Stopped` or `Suspended` state; `restart` only works for `Running` instances; `stop` only works for `Running` instances, with `--force` as a last resort for non-responsive/unknown/suspended state.  
   Sources: Multipass `start`, `restart`, `stop` references.

3. `multipass mount` maps a host directory to an instance path and persists until explicitly unmounted; `multipass umount` removes mounts. `transfer` is a reliable fallback for copying files if mounts fail.  
   Sources: “Share data with an instance” and `umount` references.

4. `lxd init --preseed` supports full non-interactive LXD initialization and is compatible with scripted setup flows.  
   Source: LXD preseed reference.

5. `lxc info` reports live state; `lxc show` reports configuration; both are suitable for readiness checks and debugging failed launches.  
   Source: LXD `lxc show` / `lxc info` reference.

6. `lxc launch` creates and starts a container in one step, which aligns with idempotent “ensure running” patterns.  
   Source: LXD `lxc launch` reference.

## Implications for macOS Local Resilience
- Insert `multipass wait-ready --timeout <N>` before any Multipass CLI sequence to eliminate daemon-ready race conditions.
- Use state-aware remediation:
  - If VM is `Stopped`/`Suspended`: `multipass start <vm>`.
  - If VM is `Running` but unresponsive to `exec`: `multipass restart <vm>`.
  - Avoid `stop --force` unless explicitly needed; treat as a last-resort recovery path with a warning.
- For workspace mounts:
  - Attempt `multipass mount` and verify accessibility in the VM.
  - If mount fails, try `multipass umount <vm>` then re-mount.
  - If still failing, fallback to `multipass transfer` for required assets.
- LXD readiness checks can rely on `lxc info` for state and `lxc show` for configuration validation.
