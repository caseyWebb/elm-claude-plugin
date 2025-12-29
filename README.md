# Elm Claude Plugin

A Claude Code plugin that provides tools for working with Elm.

## Skills

- **elm-packages** - Query the Elm package registry, list project dependencies, and read package documentation

## Prerequisites

- `curl` - for fetching package data from package.elm-lang.org
- `jq` - for parsing JSON (install via `brew install jq` on macOS)

## Installation

### Option 1: Add as marketplace

```bash
/plugin marketplace add caseyWebb/elm-claude-plugin
/plugin install elm@caseyWebb
```

### Option 2: Clone directly

```bash
git clone https://github.com/caseyWebb/elm-claude-plugin ~/.claude/plugins/elm
```

Then restart Claude Code.

## Usage

The skill is automatically triggered when you ask about:
- Elm packages or dependencies
- elm.json contents
- Package documentation
- Function signatures in Elm packages

### Example prompts

- "What packages are installed in this Elm project?"
- "Search for Elm packages that handle JSON decoding"
- "What functions does elm/core's List module export?"
- "Show me the documentation for List.map"

## How it works

The plugin teaches Claude how to:

1. **Read elm.json directly** - Claude parses the JSON natively for listing dependencies
2. **Run shell scripts** - For network operations and efficient JSON extraction:
   - `list-installed-packages.sh` - Lists dependencies from elm.json
   - `search-packages.sh` - Queries package.elm-lang.org/search.json
   - `fetch-package.sh` - Downloads package docs to cache
   - `get-exports.sh` - Extracts module exports (compact, no docs)
   - `get-export-docs.sh` - Extracts single export with full documentation
   - `get-readme.sh` - Reads package README documentation

The scripts use jq to filter large JSON files, keeping token usage efficient.

## Cache

Package data is cached at `~/.elm/0.19.1/packages/{author}/{name}/{version}/`

This matches the standard Elm tooling cache location, so packages installed via `elm install` are already available.

## License

MIT
