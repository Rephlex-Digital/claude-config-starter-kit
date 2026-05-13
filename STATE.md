# Claude Config — State

> What's currently installed and configured. Updated when state materially changes.

**Last updated:** YYYY-MM-DD
**Machine:** [hostname]
**OS:** [macOS 14.x / Windows 11 + WSL2 Ubuntu 22.04 / etc.]
**User:** [you]

---

## Installed via this repo

| Component | Count | Notes |
|---|---|---|
| Custom agents | 0 | Add files to `agents/` and re-run `install.sh` to symlink |
| Custom hooks | 0 | Add scripts to `hooks/` and re-run `install.sh` |
| Custom commands | 0 | Add `.md` files to `commands/` and re-run `install.sh` |
| References | 0 | Add files to `references/` and re-run `install.sh` |

## Settings

- `~/.claude/settings.json` — managed via `settings.json.template` + env vars from `.env.example`
- Hooks enabled: [list, or "none yet"]
- MCP servers configured: [list, or "none yet"]

## Skills (third-party, NOT managed by this repo)

Skills are installed separately (typically via their own install scripts) and live as symlinks under `~/.claude/skills/`. Not tracked here because the source repos are the canonical version. To inventory current state:

```bash
ls -la ~/.claude/skills/
```

## Memory

- Memory lives at `~/.claude/projects/<hash>/memory/` per project, NOT in this repo.
- Memory is regenerated organically through use.
- (Future) Decide on memory sync strategy if/when working across multiple machines actively.

## Open items

- [ ] [Anything pending — e.g., "decide on hook for auto-pull at session start"]

## Recent material changes

- YYYY-MM-DD — Initial setup, install.sh run, verified clean.
