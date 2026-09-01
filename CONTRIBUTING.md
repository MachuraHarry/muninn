# Contributing to Muninn

Muninn is a personal, self-hosted AI agent written in the
[Pipe](https://github.com/MachuraHarry/pipe) scripting language. It started
as a single-user project and is now open for others to self-host and extend.

## Getting started

1. Fork and clone the repo.
2. Follow [README.md](README.md) (Quickstart) to get a local instance running
   against your own Telegram bot token and DeepSeek API key.
3. Make your change.
4. Run the test suite before opening a pull request:
   ```
   pipe -test
   ```
   All tests must pass. If you touched `.pipe` files, also run
   `pipe -ast <file>` on each changed file to catch syntax errors early.
5. If your change affects a live-running behavior (Telegram commands, the
   scheduler, Docker tooling, MCP integrations), restart your local instance
   and manually verify the change end-to-end — the test suite covers
   deterministic logic only (no AI calls, no network), not live behavior.

## Code style

- Keep changes small and focused; prefer several small, well-tested commits
  over one large one.
- Match the existing code's documentation style: functions are preceded by
  a `--!` doc comment explaining *why*, not just *what*.
- Don't add abstractions, config flags, or error handling for cases that
  can't currently happen — this codebase favors direct, readable code over
  defensive scaffolding.
- Some internal identifiers (AI tool names, agent names) are still German
  as a historical artifact — this is being addressed incrementally. New
  code should use English identifiers.

## Reporting issues

Please open a GitHub issue with a clear description of the problem and, if
possible, the exact steps or message that triggered it.

## License

By contributing, you agree that your contributions will be licensed under
the project's [MIT License](LICENSE).
