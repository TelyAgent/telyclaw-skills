---
name: briefing-generator
description: >
  Generate topic briefings from Telegram channels. Use this skill when the user mentions
  "briefing", "newsletter", "digest", "message summary", "channel recap", "generate report",
  "send briefing", "scheduled push", "channel roundup", "简报", "消息汇总", "频道摘要",
  "生成报告", "发送简报", "定时推送", or "频道整理". Also applies when users want to
  compile messages from multiple Telegram channels into structured summaries and deliver
  them to others.
---

# Briefing Generator

Help users fetch messages from Telegram channels, format them into Markdown briefings
using a selected template, deliver to Telegram contacts or via Gmail, and optionally
set up recurring scheduled generation.

## Workflow

### Step 1: Gather Configuration

When the user requests a briefing, confirm the following (skip any info already provided):

1. **Channel names** — Telegram channels to pull from (supports multiple, comma-separated).
   Users can provide channel names or usernames.
2. **Time range** — e.g. "past 24 hours", "past 7 days", or an explicit date range like
   "2026-05-15 to 2026-05-20".
3. **Template** — Choose from the four templates below. Default to "digest" if unspecified.
4. **Delivery** — Telegram contacts/groups/channels, Gmail addresses, or both.
5. **Schedule** — Whether to auto-generate on a recurring schedule (e.g. daily at 9:00 AM).

After each confirmation, echo it back clearly to ensure mutual understanding.

### Step 2: Fetch Channel Messages

Use the **telegram_get_messages** tool to retrieve messages from each specified channel.

Steps:
1. If the user gave channel names instead of chat IDs, search or look up the channel
   to get its chat ID first.
2. Based on the time range, estimate how many messages to fetch.
3. Call telegram_get_messages for each channel to get messages within the time window.
4. Collect key metadata: timestamp, message text, view count, forward count.

Guidelines:
- Fetch in batches if the channel is active — don't pull everything in one go.
- If a channel can't be found, tell the user immediately; don't silently skip it.
- Report progress when done: "Fetched Y messages across X channels."

### Step 3: Generate the Briefing

Pick one of the four templates based on user choice (default: `digest`).
Read the corresponding `templates/<name>.md` file for the exact output format and rules,
then apply it to the fetched messages.

| Template | File | Best for |
|----------|------|----------|
| Digest | `assets/templates/digest.md` | Quick scanning, one-line-per-message |
| Detailed Summary | `assets/templates/detailed.md` | In-depth reading, preserves data & stats |
| Topical | `assets/templates/topical.md` | Cross-channel topic grouping |
| Insights | `assets/templates/insights.md` | Conclusions, trends, actionable takeaways |

### Step 4: Deliver the Briefing

Show the finished briefing to the user for review before sending.
Then deliver via the method(s) the user specified.

#### Telegram Delivery

Use the **telegram_send_message** tool to send to the specified recipients.

- If the user specified a contact name, resolve it to the correct chat ID first.
- Telegram imposes a 4096-character limit per message. Split long briefings into
  multiple segments at natural paragraph boundaries. Label each segment "(1/3)", "(2/3)", etc.
- Report back when sending is complete.

#### Gmail Delivery

Use the **gmail_message_send** tool to send the briefing via email.

**Plugin Detection (required on first use):**

Before calling any Gmail tool, check whether the Gmail plugin is installed and available:

1. Scan the available tools list for `gmail_*` prefixed tools (gmail_authorize,
   gmail_message_send, etc.).
2. If no such tools are found, the Gmail plugin is not installed. Tell the user:
   > "The Gmail plugin is not installed. Please install the **Gmail** plugin from the
   > telyclaw plugin marketplace, or visit https://github.com/TelyAgent/telyclaw-plugin-gmail
   > for installation instructions. Let me know once it's set up and we'll continue."
3. If the tools exist but are unavailable (e.g. expired authorization), proceed to
   the authorization flow below.
4. If everything is ready, proceed to send.

**Authorization:**
- The first send attempt will trigger the OAuth authorization flow.
- On receiving an authorization error, use AskUserQuestion to ask the user for permission.
- Call gmail_authorize — this will open a browser window for Google OAuth.
- Tell the user: "A Google authorization page has been opened in your browser. Please
  complete the authorization and let me know when you're done."
- Once the user confirms, retry the send.

**Send parameters:**
- to: recipient email address
- subject: `{Channel names} Briefing · {date range}`
- text: the full Markdown briefing
- confirm: true (required — the tool will refuse to send without this)

The email body is the complete Markdown briefing, readable as-is.

#### Dual Delivery

If the user chose both Telegram and Gmail, execute them in sequence.
The two channels are independent.

### Step 5: Set Up Schedule (Optional)

If the user wants recurring generation, use OpenClaw's built-in cron functionality:

1. Confirm the cron expression meaning with the user (e.g. "This will run every day at 9:00 AM, correct?").
2. Use the cron tool to create the scheduled task linked to the briefing configuration.
3. Tell the user the task has been created and how to view or cancel it.

Cron expression examples:
- `0 9 * * *` — Every day at 9:00 AM
- `0 9 * * 1` — Every Monday at 9:00 AM
- `0 9,17 * * *` — Every day at 9:00 AM and 5:00 PM

---

## Interaction Principles

- **Proactive completion** — When the user's request is incomplete, ask for all
  missing information in one round; don't stretch it across multiple turns.
- **Echo and confirm** — Restate key config (channels, time range, recipients)
  before execution to ensure alignment.
- **Transparent progress** — Report progress while fetching messages; mention
  which template is being used when generating.
- **Clear error handling** — If a channel can't be found, messages are empty, or
  sending fails, clearly explain the issue and suggest a fix.
- **Preview before sending** — Always show the briefing to the user for review
  before delivering it.
