# Lesson 21: Local Desktop Mode

**Duration:** 5 minutes

## What You'll Learn

- How local desktop mode works
- Entering and exiting your ACFS sandbox
- Managing your workspace
- Accessing the dashboard

---

## What Is Local Desktop Mode?

Unlike the standard VPS installation, **local desktop mode** runs ACFS inside an isolated LXD container on your Ubuntu PC. This means:

- ✅ Your host system is never modified
- ✅ Passwordless sudo and agent permissions are safely sandboxed  
- ✅ You can experiment freely without risk
- ✅ Easy cleanup: just destroy the container

> **Think of it like:** A virtual machine, but lighter and faster. Your coding environment lives in its own bubble.

---

## Entering Your ACFS Sandbox

After installation, your ACFS environment lives inside a container. To enter it:

```bash
acfs-local shell
```

> **Note:** `acfs-local` is a host-side wrapper installed to `~/.local/bin` during local install.
> If it isn't found, open a new terminal or add it to your PATH:
>
> ```bash
> export PATH="$HOME/.local/bin:$PATH"
> ```

You'll see a prompt like:

```
ubuntu@acfs-local:~$
```

This is your sandboxed environment. All your agents and tools are here!

To exit and return to your host:

```bash
exit
```

---

## Your Workspace

Your projects are shared between host and container:

| Location | Description |
|----------|-------------|
| **Host:** `~/acfs-workspace/` | On your regular desktop |
| **Container:** `/data/projects/` | Same files, accessible inside sandbox |

Files you create in either location appear in both places instantly.

**Example:**

```bash
# On host
touch ~/acfs-workspace/hello.txt

# Inside container
ls /data/projects/
# → hello.txt
```

---

## Useful Commands

| Command | What It Does |
|---------|--------------|
| `acfs-local shell` | Enter sandbox shell |
| `acfs-local status` | Show container state and access info |
| `acfs-local start` | Start the container |
| `acfs-local stop` | Stop the container |
| `acfs-local dashboard` | Open dashboard in browser |
| `acfs-local doctor` | Run health check inside container |
| `acfs-local destroy` | Remove container (keeps workspace) |

---

## Accessing the Dashboard

The ACFS dashboard is available at:

```
http://localhost:38080
```

Or run:

```bash
acfs-local dashboard
```

This automatically opens your browser to the dashboard.

---

## Working with Agents

Once inside the sandbox (`acfs-local shell`), all your agents work normally:

```bash
# Claude Code (vibe mode)
cc "Build a hello world API"

# Codex  
cod

# Gemini
gmi

# Amp (optional)
amp
```

Remember: These agents have full permissions **inside the sandbox**, but cannot touch your host system.

---

## Container Lifecycle

Your container persists across reboots! But you can manage it:

**Stopping (saves resources):**
```bash
acfs-local stop
```

**Starting back up:**
```bash
acfs-local start
```

**Complete removal:**
```bash
acfs-local destroy
```

> **Note:** Destroying the container keeps your `~/acfs-workspace` files safe. Only the container environment is removed.

---

## Quick Reference

| Task | Command |
|------|---------|
| Enter environment | `acfs-local shell` |
| Check status | `acfs-local status` |
| Run agents | Inside shell: `cc`, `cod`, `gmi` |
| Access projects | Host: `~/acfs-workspace` |
| View dashboard | `acfs-local dashboard` |
| Health check | `acfs-local doctor` |

---

## Troubleshooting

**Container won't start?**
```bash
lxc list          # Check container state
lxc info acfs-local    # View detailed info
```

**Need to reinstall?**
```bash
acfs-local destroy --force
acfs-local create
```

**Low on disk space?**
The container uses ~5-10GB. Check with:
```bash
df -h ~/snap/lxd/
```

---

## Next Steps

- Run `acfs-local shell` and try `acfs doctor`
- Create a project in `~/acfs-workspace`
- Launch an agent with `cc "describe this project"`

**Congratulations!** You're ready to use ACFS on your desktop safely. 🎉
