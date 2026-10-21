# Contributing to Lukas

Thanks for helping! Lukas is a free, open-source personal finance app: your budget, and you'll actually enjoy looking after it; see the [README](README.md) and the [design spec](docs/superpowers/specs/2026-10-20-lukas-design.md).

## Setup

Requirements: Node 22, pnpm 12, Docker.

```bash
pnpm install
pnpm lint
pnpm typecheck
pnpm test
```

## Conventions

- Everything in the repository is written in English (code, comments, docs, commits).
- Commits follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat(api): …`, `fix(core): …`).
- Write the failing test first, then the code.
- Money is always an integer number of cents, never a float.
- **Never commit real financial data.** Test fixtures must be invented.
