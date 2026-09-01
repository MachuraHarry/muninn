# Muninn User Guide

This is a practical, task-oriented guide to actually *using* Muninn once it's
running. For installation and architecture, see [README.md](README.md). If
you just want a quick reference of every command, jump to
[Command Reference](#command-reference).

## What Muninn is

Muninn is a personal AI agent you talk to through Telegram (and optionally a
web dashboard). It's not a stateless chatbot — it has a persistent memory
("soul"), can research the web, generate and read documents and images,
understand voice messages, run isolated Docker containers, and act on a
schedule (reminders, a daily briefing, proactive check-ins) — all without
you needing to learn any special syntax. Almost everything works through
plain natural language; the handful of slash commands that exist are
shortcuts for things that need to be unambiguous (like `/remind`), not the
primary interface.

## Getting started

Open a chat with your bot and send `/start`. Muninn introduces itself and is
immediately usable — just write what you want, in whatever language you
like (see [Settings](#settings) for controlling which language it replies
in).

There's no onboarding flow to complete. A few things worth knowing up front:

- **Muninn remembers things across conversations.** If you tell it "I'm
  vegetarian" today, it can use that fact weeks later without you repeating
  yourself.
- **You don't need to phrase things like commands.** "Remind me to call the
  dentist tomorrow at 9" works exactly as well as `/remind` — Muninn parses
  the intent either way.
- **Long or complex requests are fine.** Behind the scenes, a "committee" of
  specialized AI agents (planner, fact-checker, critic, registrar, plus
  per-tool specialists) breaks the task down and hands it between each other
  — you just see the final answer, with a live status line while it works.

## Talking to Muninn

Just write naturally. Some things that work well:

- **Questions**: "What's the capital of Kazakhstan?", "What did I tell you
  about my allergy last month?"
- **Facts to remember**: "Remember that I prefer window seats.", "My
  girlfriend's birthday is March 3rd."
- **Tasks**: "Look up the current price of Bitcoin and summarize it.",
  "Write a short report on renewable energy trends and send it to me as a
  Word document."
- **Reminders with natural time references**: "Remind me in 20 minutes to
  check the oven.", "Remind me tomorrow at 8am about the meeting."
- **Follow-ups**: Muninn keeps the last ~12 messages of context per chat, on
  top of its long-term memory, so you can just continue a thought without
  repeating yourself.

Under most answers you'll see inline buttons:

- **💾 Save** — store the answer as a permanent memory.
- **🔍 Dig deeper** — ask Muninn to research the topic further.
- **👍 / 👎** — tell Muninn whether an answer was useful; this adjusts how
  important that memory is considered in the future.

While Muninn is working on something non-trivial, it edits a single status
message live (e.g. "🧭 Planning the answer...", "🔧 Using filesystem... →
calling list_directory") instead of going silent — so you always know it's
still working, and roughly what it's doing.

## Command Reference

All commands are also visible in Telegram's native `/` menu (tap the menu
button next to the input field).

| Command | What it does |
|---|---|
| `/start` | Greeting / introduction |
| `/help` | Show all commands |
| `/status` | Current state (memory count, provider, committee, executor) |
| `/costs` | Summary of AI usage costs (sessions, tokens, $) |
| `/list` | Your most important stored memories |
| `/search <query>` | Web research with cited sources |
| `/learn <URL>` | Learn a document from a URL (or just send a `.txt`/`.md` file or a PDF directly — see [Documents](#documents--files)) |
| `/graph <name>` | Query the knowledge graph (e.g. `/graph Alice` — related facts/entities) |
| `/remind <instruction>` | Schedule a reminder (e.g. `/remind in 10 minutes take a break`) — same as just asking naturally |
| `/reminders` | List your open reminders/briefings |
| `/briefing` | Turn on the daily morning briefing (`/briefing stop` to cancel) |
| `/reset` | Clear the current conversation thread (fresh context for follow-ups; long-term memory is untouched) |
| `/consolidate` | Manually trigger memory consolidation ("dreaming" — see [Memory](#memory--long-term-recall)) |
| `/settings` | Open the settings menu (see [Settings](#settings)) |
| `/stop` | **Immediately** cancel all running background Docker jobs and scheduled continuations — reliable and instant, doesn't depend on the AI's judgment |

## Core capabilities

### Memory & long-term recall

Muninn's memory ("soul") is a local SQLite database, not a black box:

- **Permanent facts** ("Remember that...") are deduplicated and never
  automatically forgotten.
- **Everything else** (tasks, casual facts, research results) slowly loses
  importance over time and is eventually forgotten if never reinforced. This
  aging only happens when `/consolidate` runs — it's not automatic inside
  the bot itself, so run it occasionally yourself, or set up an external
  cron job for it (see README). How aggressively memories fade once
  consolidation runs is configurable, see [Settings](#settings) → Memory.
- **Retrieval** combines keyword matching with semantic search, so you can
  ask about something in different words than you originally used it.
- **Knowledge graph**: entities and relationships extracted from
  conversations (`/graph <name>` to explore).
- Nothing here needs to be managed manually — it's designed to just work in
  the background. `/list` and `/graph` are there if you're curious what
  Muninn actually remembers.

### Web research

Ask a question Muninn doesn't already know the answer to, and it
automatically searches the web (DuckDuckGo + Wikipedia, no API key
involved), reads the most relevant pages, and answers with real content
and cited sources — never a guess presented as fact.

### Documents & files

- **Send a `.txt`/`.md` file, a PDF, or a page URL** (`/learn <URL>`) —
  Muninn reads and learns the content into memory, so you can later ask
  questions about it. Uploaded PDFs are handled via local text extraction
  (no cloud service); scanned image-only PDFs without a real text layer
  can't be read this way. Note: `/learn <URL>` currently works for regular
  web pages, not PDF links — send the PDF itself as a file instead.
- **Ask for a document or presentation** ("write this up as a Word
  document", "make me a short slide deck about X") and Muninn creates a
  real `.docx`/`.pptx` file and sends it to you directly.
- Any file Muninn creates or finds (a screenshot, a generated document) is
  always actually sent to you — it doesn't just describe having a file
  without attaching it.

### Photos & images

- **Send a photo** (optionally with a caption as a question) and Muninn
  describes/analyzes it.
- **Ask for a new image** ("draw me a picture of a lighthouse at sunset")
  and Muninn generates and sends one — free, no API key.

### Voice messages

- **Send a voice message** — Muninn transcribes it locally (no cloud
  speech-to-text service) and processes the text exactly like a typed
  message; commands, reminders and everything else work identically.
- **Muninn can reply with voice** for conversational answers when it makes
  sense (summaries, casual chat) — it decides based on context; for
  action-oriented answers (files sent, reminders set, links, code) it
  always replies with text instead, since those don't work well spoken.

### Reminders & the daily briefing

- Natural language ("remind me...") or `/remind` — both go through the same
  parser, AI-based with a deterministic fallback if the AI call fails.
- `/briefing` sets up a daily message (default 8am, configurable via
  `.env`) summarizing your top memories, open goals, and recent activity —
  enriched with real calendar events if Google Calendar is connected.

### Proactivity

Muninn can act without you writing first:

- **Proactive calendar reminders** — if Google Calendar is connected,
  Muninn checks every 15 minutes for upcoming events and pings you shortly
  before they start.
- **Daily self-check** — once a day, Muninn looks through its own memory
  for open tasks, unfinished work, or upcoming deadlines and reaches out
  if there's something genuinely worth mentioning. If there's nothing
  notable, it stays silent — no filler messages.
- **Self-diagnosis** — Muninn keeps a structured log of its own internal
  errors and checks it once a day; if the same failure has happened
  repeatedly (e.g. an expired Google token), it tells you proactively
  instead of you having to notice something's broken.

All of this is controlled by one switch: `/settings` → Proactive messages.
The daily briefing is separate and always opt-in via `/briefing`.

### Docker & background tasks

Muninn can spin up isolated Docker containers to actually *do* things, not
just talk about them — structurally sandboxed (no volume mounts, no
`--privileged`, no host access) so this is safe to use freely:

- **"Test this GitHub repo"** — give Muninn a repo URL and ask it to test
  it. It clones, builds, and runs the real test suite inside an isolated
  container in the background, then reports back with the actual results
  (pass/fail counts, real error output) — no guessing.
- **Background setups** — anything that takes a while (installing
  packages, setting something up) runs in the background; Muninn replies
  immediately ("started, I'll let you know") and follows up automatically
  once it's done, instead of leaving you waiting on a blocked chat.
- **Reusable environments** — if you need a Linux/Docker environment you'll
  come back to repeatedly (not a one-off test), Muninn can register it and
  reuse the same container next time instead of creating a new one every
  time.
- **`/stop`** always works, immediately, regardless of what the AI is doing
  — see [Command Reference](#command-reference).

### Recipes

When Muninn completes a multi-step task that looks like a reusable pattern
(e.g. "fetch the BTC price from a specific site, summarize it, send as
voice"), it can save the steps as a named "recipe." Next time a similar
request comes in, it checks for a matching recipe first instead of figuring
out the approach from scratch.

### Google Workspace (optional)

If connected (see README for setup), Muninn can send Gmail, and read/write
Google Drive and Calendar on your behalf. If it's not connected yet and you
ask for something that needs it, it walks you through the one-time
authorization instead of just saying it can't help.

### MCP tools

Muninn can be extended with any [Model Context
Protocol](https://modelcontextprotocol.io) server (filesystem access,
GitHub, databases, whatever exists or whatever you build) — each connected
server gets its own dedicated specialist inside the committee, so adding a
new tool doesn't require any prompt engineering to make Muninn "aware" of
it.

### Web dashboard

If enabled (see README), a browser-based dashboard mirrors Muninn's memory,
goals, knowledge graph, recent activity, connected tools, and cost tracking
— useful for browsing what Muninn knows without going through chat, or for
talking to it from a keyboard instead of a phone.

## Settings

`/settings` opens an inline menu — tap a button to cycle its value; changes
apply immediately, no need to confirm.

| Setting | Values | Default | Effect |
|---|---|---|---|
| Style | terse / normal / detailed | normal | How concise or elaborate AI-generated answers are |
| Language | German / English | German | Language for AI-generated answers (deterministic UI text like `/help` is not affected by this toggle) |
| Proactive messages | on / off | on | Whether Muninn ever messages you unprompted (self-check, calendar pings, self-diagnosis) — the daily briefing is separate and stays opt-in via `/briefing` regardless |
| Memory | lenient / normal / strict | normal | How aggressively old, non-permanent memories fade and get forgotten during consolidation |

(Button labels in the menu itself are still German as of this writing — the
values above are the underlying meaning, translated menu text is part of
the ongoing English migration.)

## Tips for getting good results

- **Be as specific as you'd be with a competent assistant.** "Summarize
  today's tech news" works, but "Summarize today's tech news, focus on AI
  and hardware, keep it to 5 bullet points" gets you a much more useful
  answer on the first try.
- **You can correct Muninn mid-task.** If an answer or approach isn't what
  you wanted, just say so — it doesn't need to be phrased as a new request.
- **If something needs a file/image/document as output, say so explicitly**
  ("...and send it to me as a PDF" / "...as a voice message") — otherwise
  Muninn picks the format it judges most appropriate for the content.
- **Long-running or multi-step tasks don't need to be split up manually.**
  Muninn recognizes when something needs more time than a single reply
  cycle and continues automatically in the background, following up when
  it's done.

## Privacy & safety notes

- All memory lives locally in a SQLite database on your own server — never
  sent anywhere except as needed context for individual AI calls to the
  configured provider.
- Docker-based actions are structurally sandboxed (see
  [Docker & background tasks](#docker--background-tasks)) — this is a
  deliberate design choice, not a missing feature, so don't expect volume
  mounts or `--privileged` to become available.
- Muninn will tell you honestly when it can't do something or when an
  action didn't actually happen, rather than claiming success it didn't
  achieve — this is a deliberate behavioral rule, not just a hope.

## Troubleshooting

- **"Muninn isn't responding"** — check `systemctl status muninn` and
  `journalctl -u muninn -f` on the server. See README's "Produktionsbetrieb"
  section (production operation — the README is still being translated to
  English as of this writing).
- **Google features stopped working** — the OAuth token expires every 7
  days in testing mode (see README's Google Workspace section); Muninn will
  tell you when re-authorization is needed and hand you the exact link.
- **A background Docker job seems stuck** — use `/stop` to cancel
  everything immediately, or just wait; jobs are checked periodically and
  will report back or fail out on their own.
- **Something silently isn't working** — check the self-diagnosis feature
  ([Proactivity](#proactivity)) or `journalctl -u muninn` directly; as of
  this guide, most previously-silent failure points now log a reason.
