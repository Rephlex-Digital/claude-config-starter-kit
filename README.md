# Taylor's Claude Config

This is the portable, git-tracked half of Taylor's Claude Code setup. The other half is the workspace repo (`arovia/`). Together, they make any laptop a 15-minute restoration.

> **Naming this repo:** suggested name is `taylor-claude-config` (or `<yourname>-claude-config`). Keep it private — it can reference secrets even if it never holds them.

---

## What lives here

| File / folder | What it is | Why git-tracked |
|---|---|---|
| `STATE.md` | What's currently configured on the live machine | So future-you knows what's set up without inspecting files |
| `RESTORE.md` | Step-by-step new-machine restoration procedure (human + AI readable) | The recursive primitive — paste it to Claude on a fresh laptop, get walked through restoration |
| `settings.json.template` | Claude Code settings with placeholders for env vars | Real `settings.json` may contain secrets; this is the safe-to-share version |
| `.env.example` | List of expected environment variables | So new-machine setup knows what secrets to source |
| `install.sh` | Symlink installer — links files here to `~/.claude/` | Idempotent; backs up existing files before linking |
| `agents/` | Custom Claude Code subagents (markdown files) | Reusable across machines |
| `hooks/` | Shell scripts run by Claude Code on session start/stop/tool-use | Reusable; portable |
| `commands/` | Custom slash commands | Reusable |
| `references/` | Static reference material Claude can read on demand | Reusable |

---

## What's NOT in this repo (and why)

- **Real `settings.json`** with API keys — gitignored. Lives only in `~/.claude/settings.json` after install. The `.template` version uses `${ENV_VAR}` placeholders.
- **Real `.env` file** with secret values — gitignored. Lives only locally. The `.example` file lists which variables to set.
- **Memory files** (`~/.claude/projects/<hash>/memory/`) — these are conversation history and may contain confidential project content. Memory is per-project and per-machine. (Future work: decide on a sync strategy. For now, treat memory as machine-local.)

---

## Quick start (new machine)

1. Install Claude Code: https://claude.com/claude-code
2. `git clone <this-repo-URL> ~/claude-config`
3. `cd ~/claude-config && bash install.sh`
4. Set environment variables from `.env.example` (typically in `~/.zshrc` or `~/.bashrc`)
5. Open VS Code → start Claude Code → paste:
   > Read RESTORE.md and walk me through verifying my setup.

The last step is the recursive trick — Claude reads its own restoration doc and finishes the job.

---

## Maintenance

- After installing a new agent / hook / command, add it under the right folder here, commit, push. It's now portable.
- After changing `~/.claude/settings.json`, update `settings.json.template` to match (with placeholders), commit, push.
- Update `STATE.md` whenever the configured state materially changes.

## On Windows

Claude Code on Windows runs in **WSL2** or **Git Bash**. `install.sh` is bash — run it from one of those environments. Symlinks behave correctly in WSL2; in Git Bash you may need to enable Developer Mode or run as admin for symlink creation.
