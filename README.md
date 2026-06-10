# TelyClaw Skills

A collection of agent skills compatible with Telyclaw (Claude Code), Codex CLI, and OpenClaw.

## Skills

### TG Message Assistant (`tg-message-assistant`)

Generate topic briefings from Telegram channels, format them into Markdown digests, and deliver via Telegram or Gmail.

**Multi-platform** — shared core workflow (`core/prompt.md`) with platform-specific adapters.
Each adapter presents the user with a choice: **browser automation** (recommended, zero setup)
or **API/MCP tools** (faster, requires credentials).

| Platform | Adapter | Primary Approach | Alternative |
|----------|---------|-----------------|-------------|
| Telyclaw (Claude Code) | `./SKILL.md` (root) | Native API tools | — |
| Codex CLI | `adapters/codex/SKILL.md` | Browser automation | MCP servers (mcp-telegram, email-mcp) |
| OpenClaw | `adapters/openclaw/SKILL.md` | Browser automation | Native channel + ClawHub skills |

#### Installation

```bash
git clone <repo-url> ~/telyclaw-skills

# Telyclaw (Claude Code) — uses root SKILL.md directly
ln -s ~/telyclaw-skills/tg-message-assistant ~/.claude/skills/tg-message-assistant

# Codex CLI — replace SKILL.md with the Codex adapter, then symlink
cp ~/telyclaw-skills/tg-message-assistant/adapters/codex/SKILL.md \
   ~/telyclaw-skills/tg-message-assistant/SKILL.md
ln -s ~/telyclaw-skills/tg-message-assistant ~/.agents/skills/tg-message-assistant

# OpenClaw — replace SKILL.md with the OpenClaw adapter, then symlink
cp ~/telyclaw-skills/tg-message-assistant/adapters/openclaw/SKILL.md \
   ~/telyclaw-skills/tg-message-assistant/SKILL.md
ln -s ~/telyclaw-skills/tg-message-assistant ~/.openclaw/skills/tg-message-assistant
```

> **Note:** On first use, the skill will ask the user to choose between browser automation
> (zero setup) and API/MCP tools (faster, requires credentials). See each adapter for details.

## Repository Structure

```
tg-message-assistant/
├── SKILL.md                    # Telyclaw adapter (native tools) — active by default
├── core/
│   └── prompt.md               # Platform-agnostic 5-step workflow
├── adapters/
│   ├── codex/SKILL.md          # Codex adapter (browser-first, MCP alternative)
│   └── openclaw/SKILL.md       # OpenClaw adapter (browser-first, native alternative)
├── assets/
│   └── templates/              # Briefing templates (digest, detailed, topical, insights)
├── references/
│   └── multi-platform-research.md
└── scripts/
```
