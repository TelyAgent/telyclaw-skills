# telyclaw-skills

TelyClaw platform skills repository. Each subdirectory is a self-contained skill published to [ClawHub](https://clawhub.ai/).

## Repository Structure

```
telyclaw-skills/
├── .env                        # Local config (gitignored)
├── .env.example                # Config template
├── scripts/
│   └── publish.sh              # Publish automation
├── briefing-generator/          # Example skill
│   ├── SKILL.md                # Skill manifest (required)
│   └── assets/                 # Supporting files
│       └── templates/
└── your-skill/                 # Each skill = one folder
    ├── SKILL.md
    └── ...
```

## Creating a New Skill

### 1. Create the folder and SKILL.md

```bash
mkdir -p my-skill
```

Create `my-skill/SKILL.md` with YAML frontmatter:

```yaml
---
name: my-skill
description: What this skill does. Include trigger keywords for skill matching.
version: 1.0.0
metadata:
  openclaw:
    requires:
      bins:
        - curl
    emoji: "\U0001F4F0"
    homepage: https://github.com/TelyAgent/telyclaw-skills
---

# My Skill

Skill instructions in Markdown...
```

### 2. Bump version on changes

When you modify a skill, increment `version` in its `SKILL.md` frontmatter. The publish script only uploads skills whose local version differs from the registry.

### 3. Publish

```bash
./scripts/publish.sh --dry-run    # preview
./scripts/publish.sh              # publish
```

## Configuration

Copy `.env.example` to `.env` and set your defaults:

```bash
cp .env.example .env
```

| Variable | Description | Default |
|----------|-------------|---------|
| `CLAWHUB_OWNER` | Publisher handle (personal or org) | (none) |

The ClawHub API token is managed by `clawhub login` and stored by the CLI — no need to put it in `.env`.

## Publishing Script

### Quick Start

```bash
# First time only
npm install -g clawhub
clawhub login

# Then
./scripts/publish.sh --dry-run    # Preview — always run this first
./scripts/publish.sh              # Publish all new/changed skills
```

### Options

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview without uploading |
| `--skill <name>` | Publish a single skill folder |
| `--owner <handle>` | Override `CLAWHUB_OWNER` from `.env` |
| `--help` | Show usage |

### How It Decides What to Publish

The default mode (`./scripts/publish.sh`, no `--skill`) runs `clawhub sync --all`, which:

1. Scans all subdirectories for `SKILL.md` files
2. Compares each local version against the registry
3. **Only uploads skills that are new or have a version bump**

Example:
```
To sync: - briefing-generator  LOCAL CHANGES latest 1.0.0; publish 1.0.1
          Already synced: other-skill@1.0.0   ← skipped, no change
```

This means you only need to bump the version in `SKILL.md` for skills you want to publish — the script handles the rest automatically.

### Single Skill Mode

When you want to publish one specific skill unconditionally:

```bash
./scripts/publish.sh --skill my-skill
```

### Override Owner

```bash
./scripts/publish.sh --owner @personal-account
```

## SKILL.md Frontmatter Reference

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Skill slug (lowercase + hyphens), used in URL |
| `description` | Yes | Summary shown in search/UI and used for skill matching |
| `version` | Yes | Semver (e.g. `1.0.0`), bump on every publish |
| `metadata.openclaw.requires.env` | No | Required environment variables |
| `metadata.openclaw.requires.bins` | No | Required CLI binaries |
| `metadata.openclaw.primaryEnv` | No | Primary credential env var name |
| `metadata.openclaw.emoji` | No | Display emoji |
| `metadata.openclaw.homepage` | No | URL to docs/repo |

Full spec: [ClawHub SKILL.md Format](https://github.com/openclaw/clawhub/blob/main/docs/skill-format.md)
