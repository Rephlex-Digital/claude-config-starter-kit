#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────
#  claude-config installer
#
#  Symlinks files in this repo into ~/.claude/ so Claude Code picks them
#  up automatically. Backs up any existing target files before linking.
#  Renders settings.json.template → ~/.claude/settings.json with
#  environment variables substituted.
#
#  Usage:
#    bash install.sh           # install + render settings.json
#    bash install.sh --verify  # check every expected symlink without changes
#
#  Idempotent: safe to re-run. On re-run:
#    - existing correct symlinks are left alone
#    - real files at target paths are backed up to <path>.backup-<timestamp>
#    - broken symlinks are repaired
# ──────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# ── helpers ──────────────────────────────────────────────────────────

# link_into <source-relative-to-repo> <target-relative-to-~/.claude>
# Idempotent symlink. Backs up real files (not symlinks) before replacing.
link_into() {
    local src="$SCRIPT_DIR/$1"
    local target="$CLAUDE_DIR/$2"
    local target_dir
    target_dir="$(dirname "$target")"

    if [ ! -e "$src" ]; then
        printf "  · skip: %s does not exist in repo\n" "$1"
        return 1
    fi

    mkdir -p "$target_dir"

    if [ -L "$target" ]; then
        local current
        current="$(readlink "$target")"
        if [ "$current" = "$src" ]; then
            printf "  ✓ already linked: %s\n" "$2"
            return 0
        else
            rm "$target"
        fi
    elif [ -e "$target" ]; then
        # Real file or directory — back it up first.
        local backup="$target.backup-$TIMESTAMP"
        mv "$target" "$backup"
        printf "  ! backed up existing %s → %s\n" "$2" "$(basename "$backup")"
    fi

    ln -s "$src" "$target"
    printf "  + linked: %s → %s\n" "$2" "$1"
    return 0
}

check_symlink() {
    local path="$1"
    local label="$2"
    if [ -L "$path" ] && [ -e "$path" ]; then
        printf "  ✓ %s\n" "$label"
        return 0
    elif [ -L "$path" ] && [ ! -e "$path" ]; then
        printf "  ✗ %s — BROKEN symlink (target missing)\n" "$label"
        return 1
    else
        printf "  ✗ %s — MISSING\n" "$label"
        return 1
    fi
}

# render <template-path> <output-path>
# Substitutes ${VAR} placeholders with environment values. Refuses to
# write a file containing unsubstituted ${} placeholders.
render() {
    local tmpl="$1"
    local out="$2"

    if [ ! -f "$tmpl" ]; then
        printf "  · skip render: %s not found\n" "$tmpl"
        return 1
    fi

    # Back up existing real file
    if [ -e "$out" ] && [ ! -L "$out" ]; then
        local backup="$out.backup-$TIMESTAMP"
        mv "$out" "$backup"
        printf "  ! backed up existing %s → %s\n" "$out" "$(basename "$backup")"
    fi

    local rendered
    rendered="$(envsubst < "$tmpl")"

    if echo "$rendered" | grep -q '\${[A-Z_]\+}'; then
        printf "  ✗ render: %s still contains unsubstituted \${VAR} placeholders.\n" "$out"
        printf "    Set the missing env vars (see .env.example) and re-run.\n"
        return 1
    fi

    echo "$rendered" > "$out"
    printf "  + rendered: %s\n" "$out"
    return 0
}

# ── verify mode ──────────────────────────────────────────────────────

if [ "${1:-}" = "--verify" ]; then
    echo "═════════════════════════════════════════════"
    echo "║  claude-config — Verify                   ║"
    echo "═════════════════════════════════════════════"
    echo ""

    pass=0
    fail=0

    echo "── Top-level files ──"
    if check_symlink "$CLAUDE_DIR/CLAUDE.md" "~/.claude/CLAUDE.md"; then pass=$((pass+1)); else fail=$((fail+1)); fi

    echo ""
    echo "── settings.json (rendered, not symlinked) ──"
    if [ -f "$CLAUDE_DIR/settings.json" ]; then
        if grep -q '\${[A-Z_]\+}' "$CLAUDE_DIR/settings.json"; then
            printf "  ✗ ~/.claude/settings.json — contains unsubstituted \${VAR}\n"
            fail=$((fail+1))
        else
            printf "  ✓ ~/.claude/settings.json (rendered)\n"
            pass=$((pass+1))
        fi
    else
        printf "  ✗ ~/.claude/settings.json — MISSING\n"
        fail=$((fail+1))
    fi

    echo ""
    echo "── Agents ──"
    if [ -d "$SCRIPT_DIR/agents" ]; then
        for f in "$SCRIPT_DIR/agents"/*.md; do
            [ -f "$f" ] || continue
            name="$(basename "$f")"
            if check_symlink "$CLAUDE_DIR/agents/$name" "agents/$name"; then pass=$((pass+1)); else fail=$((fail+1)); fi
        done
    fi

    echo ""
    echo "── Hooks ──"
    if [ -d "$SCRIPT_DIR/hooks" ]; then
        for f in "$SCRIPT_DIR/hooks"/*; do
            [ -f "$f" ] || continue
            name="$(basename "$f")"
            [ "$name" = ".gitkeep" ] && continue
            if check_symlink "$CLAUDE_DIR/hooks/$name" "hooks/$name"; then pass=$((pass+1)); else fail=$((fail+1)); fi
        done
    fi

    echo ""
    echo "── Commands ──"
    if [ -d "$SCRIPT_DIR/commands" ]; then
        for f in "$SCRIPT_DIR/commands"/*.md; do
            [ -f "$f" ] || continue
            name="$(basename "$f")"
            if check_symlink "$CLAUDE_DIR/commands/$name" "commands/$name"; then pass=$((pass+1)); else fail=$((fail+1)); fi
        done
    fi

    echo ""
    echo "── References ──"
    if check_symlink "$CLAUDE_DIR/references/claude-config" "references/claude-config (dir)"; then pass=$((pass+1)); else fail=$((fail+1)); fi

    echo ""
    echo "═════════════════════════════════════════════"
    printf "  Results: %d passed, %d failed\n" "$pass" "$fail"
    if [ "$fail" -eq 0 ]; then
        echo "  ✓ All checks passed."
    else
        echo "  ⚠ Run 'bash install.sh' to fix."
    fi
    echo ""
    echo "INSTALLED:$pass SKIPPED:0"
    exit "$fail"
fi

# ── install mode ─────────────────────────────────────────────────────

echo "═════════════════════════════════════════════"
echo "║  claude-config — Install                  ║"
echo "═════════════════════════════════════════════"
echo ""
echo "Repo:   $SCRIPT_DIR"
echo "Target: $CLAUDE_DIR"
echo ""

mkdir -p "$CLAUDE_DIR" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/references"

installed=0
skipped=0

# Top-level CLAUDE.md (only if a CLAUDE.md exists at repo root — optional)
if [ -f "$SCRIPT_DIR/CLAUDE.md" ]; then
    echo "── Top-level ──"
    if link_into "CLAUDE.md" "CLAUDE.md"; then installed=$((installed+1)); else skipped=$((skipped+1)); fi
    echo ""
fi

# settings.json (render, don't symlink — the rendered file has secrets resolved)
echo "── settings.json ──"
if render "$SCRIPT_DIR/settings.json.template" "$CLAUDE_DIR/settings.json"; then
    installed=$((installed+1))
else
    skipped=$((skipped+1))
fi
echo ""

# Agents
echo "── Agents ──"
if [ -d "$SCRIPT_DIR/agents" ]; then
    found=0
    for f in "$SCRIPT_DIR/agents"/*.md; do
        [ -f "$f" ] || continue
        found=1
        name="$(basename "$f")"
        if link_into "agents/$name" "agents/$name"; then installed=$((installed+1)); else skipped=$((skipped+1)); fi
    done
    [ "$found" = 0 ] && echo "  · (no agents to install yet)"
fi
echo ""

# Hooks
echo "── Hooks ──"
if [ -d "$SCRIPT_DIR/hooks" ]; then
    found=0
    for f in "$SCRIPT_DIR/hooks"/*; do
        [ -f "$f" ] || continue
        name="$(basename "$f")"
        [ "$name" = ".gitkeep" ] && continue
        found=1
        if link_into "hooks/$name" "hooks/$name"; then
            chmod +x "$f" 2>/dev/null || true
            installed=$((installed+1))
        else
            skipped=$((skipped+1))
        fi
    done
    [ "$found" = 0 ] && echo "  · (no hooks to install yet)"
fi
echo ""

# Commands
echo "── Commands ──"
if [ -d "$SCRIPT_DIR/commands" ]; then
    found=0
    for f in "$SCRIPT_DIR/commands"/*.md; do
        [ -f "$f" ] || continue
        found=1
        name="$(basename "$f")"
        if link_into "commands/$name" "commands/$name"; then installed=$((installed+1)); else skipped=$((skipped+1)); fi
    done
    [ "$found" = 0 ] && echo "  · (no commands to install yet)"
fi
echo ""

# References folder — link the whole directory under a namespaced name
echo "── References ──"
if [ -d "$SCRIPT_DIR/references" ]; then
    if link_into "references" "references/claude-config"; then
        installed=$((installed+1))
    else
        skipped=$((skipped+1))
    fi
fi
echo ""

echo "═════════════════════════════════════════════"
printf "  Installed: %d  Skipped: %d\n" "$installed" "$skipped"
echo "═════════════════════════════════════════════"
echo ""
echo "Next: run 'bash install.sh --verify' to confirm everything is wired."
echo ""
echo "INSTALLED:$installed SKIPPED:$skipped"
