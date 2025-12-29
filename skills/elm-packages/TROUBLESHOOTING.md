# Troubleshooting

This guide helps diagnose and fix issues with the elm-packages skill.

## Check Prerequisites

First, verify that required tools are installed:

```bash
which curl
which jq
```

If either command returns nothing or "not found", the tool is missing.

## Installing Prerequisites

### macOS (Homebrew)
```bash
brew install curl jq
```

### Ubuntu / Debian
```bash
sudo apt update
sudo apt install curl jq
```

### Arch Linux
```bash
sudo pacman -S curl jq
```

### Windows (WSL)
Same as Ubuntu/Debian instructions above.

### Windows (native)
- curl: Usually pre-installed on Windows 10+
- jq: Download from https://jqlang.github.io/jq/download/

## Common Errors

### "jq: command not found"

**Cause:** jq is not installed or not in PATH.

**Fix:** Install jq using the instructions above.

### "curl: command not found"

**Cause:** curl is not installed (rare on most systems).

**Fix:** Install curl using your package manager.

### "Failed to fetch package" error

**Cause:** The package couldn't be downloaded from package.elm-lang.org.

**Checks:**
1. Verify the package name and version are correct
2. Check if the package exists: https://package.elm-lang.org/packages/{author}/{name}
3. Verify internet connectivity

### "elm.json not found"

**Cause:** Not running from within an Elm project directory.

**Fix:** Navigate to a directory containing elm.json or a subdirectory of an Elm project.

### Network errors / timeouts

**Cause:** Cannot reach package.elm-lang.org

**Checks:**
1. Verify internet connectivity
2. Try: `curl -I https://package.elm-lang.org`
3. Check if behind a proxy that blocks the domain

### Permission denied on scripts

**Cause:** Scripts don't have execute permission.

**Fix:**
```bash
chmod +x scripts/*.sh
```

### Empty or invalid JSON output

**Cause:** Package doesn't exist or version is wrong.

**Checks:**
1. Verify package exists: https://package.elm-lang.org/packages/{author}/{name}
2. Check version is valid
3. Ensure package name format is `{author}/{name}` not just `{name}`

## Cache Issues

### Cache location
```
~/.elm/0.19.1/packages/{author}/{name}/{version}/
```

### Clear cache for a package
```bash
rm -rf ~/.elm/0.19.1/packages/{author}/{name}/{version}
```

### Check cache contents
```bash
ls -la ~/.elm/0.19.1/packages/{author}/{name}/{version}/
```

Should contain:
- `README.md`
- `docs.json`
- (possibly other files from elm install)

## Getting Help

If issues persist:
1. Check the package exists on https://package.elm-lang.org
2. Try fetching manually with curl to see error details
3. Verify jq version: `jq --version` (should be 1.5+)
