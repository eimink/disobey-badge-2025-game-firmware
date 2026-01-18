# Release Process

This document describes how to create releases for the Disobey Badge 2025 firmware.

## Overview

The release process consists of:
1. Bumping the semantic version number
2. Committing the version change
3. Creating a git tag with version and commit SHA
4. Building both normal and minimal firmware variants
5. Publishing to GitHub (optional in CI/CD)

## Local Testing (Safe - No Publishing)

You can test the entire release process locally without pushing anything to GitHub:

### Test a Patch Release

```bash
make release
```

This will:
- Bump patch version (e.g., v0.0.1 → v0.0.2)
- Create a commit
- Create a local tag (e.g., v0.0.2-abc1234)
- Build both firmware types
- Show instructions for publishing or undoing

### Test Different Version Bumps

```bash
# Bump minor version (e.g., v0.1.0 → v0.2.0)
make release BUMP_TYPE=minor

# Bump major version (e.g., v1.0.0 → v2.0.0)
make release BUMP_TYPE=major
```

### Verify Without Building Firmware

If you just want to test version bumping without the full build:

```bash
make bump_version BUMP_TYPE=patch
cat frozen_fs/VERSION  # Check new version
```

### Undo a Test Release

After testing, you can clean up the local changes:

```bash
# Get the tag name from the release output
git tag -l  # List all tags to find yours

# Delete the tag
git tag -d v0.0.2-abc1234

# Undo the version commit
git reset --hard HEAD~1

# Verify cleanup
git log --oneline -5
git tag -l
```

## Publishing a Real Release

Once you've tested locally and are satisfied:

### Option 1: Manual Publishing

```bash
# Create the release
make release BUMP_TYPE=minor

# Push the commit and tags to GitHub
git push origin main --tags
```

### Option 2: Via CI/CD (Recommended)

The GitHub Actions release workflow will:
1. Run `make release` with your specified version bump
2. Build firmware
3. Upload to S3 storage
4. Create GitHub Release
5. Automatically push tags

Simply trigger the workflow from GitHub Actions UI.

## Version Numbering

We use semantic versioning: `vMAJOR.MINOR.PATCH`

- **MAJOR**: Incompatible API changes or major rewrites
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

Examples:
- `v0.0.1` → `v0.0.2` (patch: bug fix)
- `v0.0.2` → `v0.1.0` (minor: new game added)
- `v0.1.0` → `v1.0.0` (major: complete rewrite)

## Firmware Variants

Each release builds two firmware variants:

1. **Normal** (`dist/firmware_normal.bin`)
   - Full game functionality
   - For conference attendees
   
2. **Minimal** (`dist/firmware_minimal.bin`)
   - Badge test screen
   - OTA update capability
   - For initial badge testing

## What Gets Built Into Firmware

The git commit SHA is embedded in the firmware at build time:

```bash
# The BUILD file contains the git SHA
cat frozen_fs/BUILD
# Output: abc1234

# This is frozen into the firmware as /readonly_fs/BUILD
```

This allows you to identify exactly which code is running on any badge.

## Troubleshooting

### "Version file not found"

Make sure you're running from the project root directory where `frozen_fs/VERSION` exists.

### "Git is not clean"

The release process requires a clean git working directory. Commit or stash your changes first:

```bash
git status
git add .
git commit -m "Prepare for release"
make release
```

### Build fails after tagging

If the build fails, you can fix the issue and rebuild without re-running the full release:

```bash
# Fix the issue, then just rebuild
make clean
make build_firmware FW_TYPE=normal
make build_firmware FW_TYPE=minimal
```

The tag and version are already set, so you don't need to redo those steps.

## Integration with CI/CD

See `.github/workflows/release.yml` for the automated release workflow that:
- Triggers manually via GitHub Actions UI
- Runs `make release`
- Uploads firmware to S3
- Creates GitHub Release
- Handles failure recovery

See `.github/workflows/build.yml` for the build-on-push workflow that:
- Builds firmware on every push to main
- Uses extensive caching for faster builds
- Runs tests (when implemented)
