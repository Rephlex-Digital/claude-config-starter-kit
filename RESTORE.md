# RESTORE — New-Machine Setup Procedure

> **AI agent reading this:** You are talking to a human who has just cloned this repo onto a fresh laptop. Your job is to walk them through the verification checklist below, run each diagnostic command for them, interpret the output, and confirm each step is healthy before moving to the next. Do NOT skip steps or batch them. After all checks pass, write a short confirmation message and update `STATE.md` with the current date and any new context.

> **Human reading this:** You can either follow these steps manually, or paste the prompt at the bottom of this file into Claude Code and let it walk you through. The AI-assisted path is faster.

---

## What this file is

A self-documenting recovery procedure for the Claude Code configuration tracked in this repo. The goal: a working environment in ~15 minutes from "fresh laptop" to "Claude Code reads my workspace correctly."

---

## Pre-requisites

| Requirement | How to check | How to install |
|---|---|---|
| git | `git --version` | macOS: bundled with Xcode CLI tools / `brew install git`. Windows: https://git-scm.com or Git Bash |
| Claude Code | `claude --version` | https://claude.com/claude-code |
| VS Code | `code --version` | https://code.visualstudio.com |
| A terminal | macOS: Terminal or iTerm2. Windows: WSL2 OR Git Bash | n/a |

---

## Verification checklist (the AI walks you through these)

### 1. Confirm clone location

This repo should be at `~/claude-config` (recommended) or a path the user remembers.

```bash
pwd
ls -la
```

Expected: see `install.sh`, `RESTORE.md`, `STATE.md`, `settings.json.template`, `.env.example`, and `agents/ hooks/ commands/ references/` folders.

### 2. Confirm Claude Code is installed

```bash
claude --version
```

If "command not found": install Claude Code (link above), then `exec $SHELL -l` to pick up the new PATH.

### 3. Set environment variables

```bash
cat .env.example
```

For each variable listed, either:
- Source from a password manager and export in `~/.zshrc` (macOS) or `~/.bashrc` / Windows env vars
- Or copy `.env.example` to `.env` (gitignored), fill in real values, and source it from the shell init file

**Verify** the critical vars are set (without printing values):

```bash
env | grep -E '^(ANTHROPIC|OPENAI|GOOGLE)_' | sed 's/=.*/=<set>/'
```

### 4. Run install.sh

```bash
bash install.sh
```

This will:
1. Back up any existing `~/.claude/` files (`.backup-YYYYMMDD-HHMMSS` suffix)
2. Create symlinks from `~/.claude/` to the files in this repo
3. Render `settings.json.template` → `~/.claude/settings.json` with env vars substituted
4. Report `INSTALLED:<count> SKIPPED:<count>`

### 5. Verify symlinks

```bash
bash install.sh --verify
```

Expected output: green checkmarks for every expected symlink. Any `✗` means follow the troubleshooting table below.

### 6. Open Claude Code and confirm session start

In VS Code, open any project folder, then start Claude Code (sidebar icon or `Cmd/Ctrl + Shift + P` → "Claude: Start session").

Ask Claude:
> What slash commands and subagents do I have available?

Expected: Claude lists the commands in `commands/` and agents in `agents/` from this repo.

### 7. Update STATE.md

When everything is verified, ask Claude to update `STATE.md` with today's date and any context worth recording (which machine, which OS, which user). Commit + push.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `claude: command not found` | Claude Code not installed or PATH not refreshed | Install + `exec $SHELL -l` |
| `install.sh: Permission denied` | Script not executable | `chmod +x install.sh` and retry |
| `install.sh --verify` shows BROKEN symlinks | The target file in this repo doesn't exist anymore | `git pull` to make sure you have the latest, then re-run install.sh |
| Symlinks fail to create on Windows | Git Bash without admin privileges OR Developer Mode off | Run Git Bash as administrator, OR enable Windows Developer Mode in Settings, OR switch to WSL2 |
| Claude Code starts but no custom commands appear | Symlinks point to wrong paths | `ls -la ~/.claude/commands/` — verify they point inside this repo. Re-run install.sh if not. |
| `${ENV_VAR}` literally appears in `~/.claude/settings.json` | The env var wasn't set when install.sh ran | Set the variable, then re-run `bash install.sh` |
| Memory missing on the new machine | Memory is intentionally NOT in this repo (per README) | Memory rebuilds organically as you work; or manually copy `~/.claude/projects/` from old machine if needed |

---

## If you get stuck

The default escalation:
1. Show Claude the error and ask it to diagnose against this file
2. If unresolved, check the `install.sh` source — it's <200 lines and well-commented
3. If still unresolved, ping Austin

---

## Prompt to paste into Claude Code on a fresh laptop

Copy everything between the lines below and paste into a new Claude Code session opened in this repo's directory.

```
I just cloned my claude-config repo onto a fresh laptop. Read RESTORE.md
and walk me through the verification checklist one step at a time. For each
step, run the diagnostic command for me, interpret the output, and confirm
the step is healthy before moving to the next. Stop and ask if anything
looks off. When everything passes, update STATE.md with today's date,
the machine name, and the OS, then suggest a commit message.
```
