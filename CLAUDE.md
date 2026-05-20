# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Claude Code skills repository for the TelyClaw platform. Each subdirectory is a self-contained skill with a `SKILL.md` file that defines its behavior, configuration, and workflow.

## Skill Structure

```
<skill-name>/
├── SKILL.md              # Skill definition with YAML frontmatter (name, description, triggers)
└── assets/               # Templates, prompts, or other resources used by the skill
```

### SKILL.md frontmatter

- `name`: The skill identifier (kebab-case)
- `description`: What the skill does and trigger keywords — this is used by Claude Code's skill matching, so it must cover the full range of user phrasings that should activate the skill

## No Build/Lint/Test

There is no build system, package manager, or test suite — this repo is pure configuration and documentation. Validation is manual: verify that `SKILL.md` frontmatter is valid YAML and that referenced asset paths resolve correctly.
