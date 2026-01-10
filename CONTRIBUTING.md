# Contributing

## Development Setup

This project uses git hooks to enforce conventional commits. To set up:

```bash
npm install
```

This installs Husky and Commitlint which validate commit messages locally.

## Commit Message Format

We use [Conventional Commits](https://www.conventionalcommits.org/). Format:

```
<type>: <description>

[optional body]
```

**Types:**
- `feat` - New feature (triggers minor version bump)
- `fix` - Bug fix (triggers patch version bump)
- `docs` - Documentation only
- `style` - Code style (formatting, semicolons)
- `refactor` - Code change that neither fixes nor adds
- `perf` - Performance improvement
- `test` - Adding/updating tests
- `build` - Build system changes
- `ci` - CI configuration changes
- `chore` - Other changes (deps, tooling)

**Examples:**
- `feat: add new package search command`
- `fix: resolve null pointer in parser`
- `docs: update README installation steps`
- `chore: update dependencies`

**Breaking changes:** Add `!` after type (e.g., `feat!: remove deprecated API`) to trigger a major version bump.

## Testing

Run the test suite:

```bash
./test.sh        # normal output
./test.sh -v     # verbose output
```

## Releases

Releases are automated via GitHub Actions. When commits are merged to `main`:

1. Commits are analyzed for conventional commit prefixes
2. Version is bumped based on commit types (`feat:` = minor, `fix:` = patch, breaking = major)
3. `plugin.json` and `marketplace.json` are updated
4. A git tag and GitHub release are created automatically

No manual versioning is required.
