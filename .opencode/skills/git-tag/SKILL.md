---
name: git-tag
description: Create semantic version git tags with changelog. Analyzes changes since last tag, suggests version bump, updates CHANGELOG.md, commits, and tags. Triggers on "release", "git tag", "new version", "bump version", "changelog".
---

# Git Tag & Release

Create semantic version git tags with automatic changelog generation.

## Workflow

### 1. Detect Current Version

```bash
git tag --sort=-v:refname | head -1
```

Parse the latest tag (e.g. `v0.2.3` → `{major: 0, minor: 2, patch: 3}`).

If no tags exist, assume `0.0.0`.

### 2. Analyze Changes Since Last Tag

```bash
git log --oneline <last_tag>..HEAD
```

If HEAD is at the last tag (no new commits), inform the user that there are no changes to release and stop.

Review each commit message to understand the scope and nature of changes.

### 3. Determine Version Bump

Based on conventional commit types in the log:

| Commit type | Bump |
|---|---|
| `feat!` or `BREAKING CHANGE` | **major** (x.0.0) |
| `feat` | **minor** (0.x.0) |
| `fix`, `build`, `ci`, `perf`, `refactor` | **patch** (0.0.x) |
| `docs`, `style`, `test`, `chore` | **patch** (0.0.x) |

Use the **highest** bump level found. If commits contain both `feat` and `fix`, use **minor**.

### 4. Ask User for Confirmation

Use the question tool to present the suggested version and ask for confirmation:

- Show the suggested version
- Show the changelog summary
- Allow the user to override the version (major/minor/patch)

**Example question:**

> Changes since v0.2.3:
> - feat: add user dashboard
> - fix: correct rating calculation
>
> Suggested version: **v0.3.0** (minor bump)
> Do you want to proceed with this version?

Options: the suggested version, and alternative bumps (major, minor, patch).

### 5. Update CHANGELOG.md

Read the current CHANGELOG.md and insert a new version section at the top (after the header).

**Format** follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/):

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- Description of new features

### Changed
- Description of changes

### Fixed
- Description of fixes

### Removed
- Description of removed features
```

**Group commits by category:**
- **Added**: `feat` commits
- **Changed**: `refactor`, behavior-changing `build`/`ci` commits
- **Fixed**: `fix` commits
- **Removed**: `revert` or explicitly removed features

**Rules:**
- Write concise, user-facing descriptions (not raw commit messages)
- Merge related commits into a single changelog entry
- Skip empty categories
- Use today's date

### 6. Commit and Tag

```bash
git add CHANGELOG.md
git commit -m "docs: add CHANGELOG for v<X.Y.Z>"
git tag v<X.Y.Z>
```

### 7. Verify

```bash
git log --oneline -3
git tag --sort=-v:refname | head -3
```

Show the user the resulting commit and tag.

## Guidelines

- NEVER push tags or commits to remote unless the user explicitly asks
- If there are uncommitted changes, warn the user and ask if they want to commit them first or ignore
- Always use the question tool for version confirmation — never assume
- Keep changelog entries concise and user-facing
- Follow conventional commit types for categorization
