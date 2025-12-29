# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code plugin that provides tools for working with Elm package documentation. It teaches Claude how to query the Elm package registry and read package docs efficiently.

## Testing

Run the test suite:
```bash
./test.sh           # normal output
./test.sh -v        # verbose output
```

The tests require `curl` and `jq` to be installed. Tests use `test-fixture/elm.json` as a sample Elm project.

## Architecture

```
.claude-plugin/
  plugin.json          # Plugin metadata (name, version, description)
  marketplace.json     # Marketplace listing info
skills/
  elm-packages/
    SKILL.md           # Skill definition with allowed tools and usage instructions
    TROUBLESHOOTING.md # User-facing troubleshooting guide
    scripts/           # Shell scripts for package operations
```

### Scripts

All scripts are in `skills/elm-packages/scripts/`:

| Script | Purpose |
|--------|---------|
| `list-installed-packages.sh` | Parse elm.json for dependencies |
| `search-packages.sh` | Query package.elm-lang.org/search.json |
| `fetch-package.sh` | Download package docs to local cache |
| `get-exports.sh` | Extract module exports (compact overview) |
| `get-export-docs.sh` | Extract single export with full docs |
| `get-readme.sh` | Read README documentation for a package |

### Cache Location

Package data is cached at `~/.elm/0.19.1/packages/{author}/{name}/{version}/`. This matches the standard Elm tooling cache location.
