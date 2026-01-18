# GitHub Actions CI/CD Setup

This document describes the GitHub Actions workflows for building and releasing the Disobey Badge 2025 firmware.

## Workflows

### 1. Build Firmware (`.github/workflows/build.yml`)

**Triggers:**
- Every push to `main` branch
- Every pull request to `main` branch

**What it does:**
- Checks out code with submodules
- Installs system dependencies and Python packages
- Caches ESP-IDF, mpy-cross, and build artifacts for faster builds
- Builds the normal firmware
- Uploads firmware artifacts (retained for 30 days)

**Caching Strategy:**
- ESP-IDF installation (~1GB) - Speeds up builds significantly
- mpy-cross compiled binary - Only rebuilds when source changes
- Build artifacts - Incremental builds when possible

**First build:** ~15-20 minutes  
**Subsequent builds:** ~5-10 minutes (with cache)

### 2. Release Firmware (`.github/workflows/release.yml`)

**Triggers:**
- Automatically when a tag starting with `v` is pushed (e.g., `v1.0.0`, `v0.0.2`)

**What it does:**
1. Checks out code at the tagged commit
2. Builds firmware with `make build_firmware`
3. Copies firmware files:
   - `firmware.bin` → `full_firmware.bin`
   - `micropython.bin` → `ota_firmware.bin`
4. Uploads firmware to S3-compatible storage (uocloud.com)
5. Creates GitHub Release with binaries attached

**Duration:** ~10-15 minutes

## Configuration

### Required Repository Secrets

Set these in GitHub repository settings → Secrets and variables → Actions:

#### S3 Storage Secrets (for firmware upload)

- `S3_ACCESS_KEY_ID` - Your S3 access key ID
- `S3_SECRET_ACCESS_KEY` - Your S3 secret access key

#### Repository Variables

- `S3_ENDPOINT` - S3 endpoint URL (e.g., `https://s3.uocloud.com`)
- `S3_BUCKET` - S3 bucket name (e.g., `disobey-firmware`)

**Note:** If S3 variables are not configured, the release workflow will skip S3 upload but still create a GitHub Release.

### Permissions

The workflows use `GITHUB_TOKEN` which is automatically provided. The release workflow requires `contents: write` permission to:
- Push commits and tags
- Create releases

This is already configured in the workflow file.

## Usage

### Automatic Builds

Builds run automatically on every push to `main`:

1. Push your changes: `git push origin main`
2. Go to Actions tab in GitHub
3. Watch the build progress
4. Download artifacts from the workflow run

### Creating a Release

To create a new release, use the local `make release` command which handles version bumping, tagging, and building:

```bash
# Create a patch release (e.g., v0.0.1 → v0.0.2)
make release

# Create a minor release (e.g., v0.1.0 → v0.2.0)
make release BUMP_TYPE=minor

# Create a major release (e.g., v1.0.0 → v2.0.0)
make release BUMP_TYPE=major
```

The `make release` command will:
1. ✅ Bump version in `frozen_fs/VERSION`
2. ✅ Commit the change
3. ✅ Create a local git tag (e.g., `v0.0.2-abc1234`)
4. ✅ Build firmware with that tag embedded
5. ✅ Show instructions for publishing

**To publish the release:**
```bash
# Push the tag to GitHub - this triggers the release workflow
git push origin main --tags
```

Once the tag is pushed, GitHub Actions will automatically:
- Build the firmware at that tagged commit
- Upload to S3 storage (if configured)
- Create GitHub Release with downloadable binaries

**Alternative: Manual tag creation**

You can also create tags manually:
```bash
# Create and push a tag directly
git tag v1.0.0
git push origin v1.0.0
```

This will trigger the release workflow, but the version in `frozen_fs/VERSION` won't be automatically updated.

### Firmware Files in Release

Each release includes three firmware files:

1. **firmware_normal.bin** - Main firmware for flashing
   - Use this for initial badge programming
   - Contains bootloader, partitions, and application
   
2. **full_firmware.bin** - Complete firmware image
   - Alternative format for some flash tools
   
3. **ota_firmware.bin** - OTA update file
   - MicroPython application only (no bootloader)
   - Use for over-the-air updates

### S3 Storage Structure

Firmware is uploaded to S3 with the following structure:

```
s3://your-bucket/
  firmware/
    v0.0.2-abc1234/          # Version-specific
      firmware_normal.bin
      full_firmware.bin
      ota_firmware.bin
    latest/                   # Always points to latest
      firmware_normal.bin
      ota_firmware.bin
```

This allows you to:
- Download specific versions by tag
- Always get the latest firmware from `/latest/` path
- Implement OTA updates pointing to `/latest/ota_firmware.bin`

## Troubleshooting

### Build fails with "Submodule not initialized"

The workflows use `submodules: recursive` which should handle this automatically. If it fails:
- Check that `.gitmodules` is correctly configured
- Ensure submodules are accessible (not private repos requiring auth)

### Build fails with ESP-IDF errors

The cache might be corrupted:
1. Go to Actions → Caches
2. Delete the `esp-idf-*` cache
3. Re-run the workflow (will take longer but rebuild cache)

### Release fails to push tags

Check that the workflow has `contents: write` permission:
- Settings → Actions → General → Workflow permissions
- Select "Read and write permissions"

### S3 upload fails

Verify your secrets are correctly set:
```bash
# Test S3 access locally
aws s3 ls s3://your-bucket/ --endpoint-url https://s3.uocloud.com
```

If successful locally but fails in GitHub Actions:
- Check secret names match exactly
- Ensure variables are set as "Variables" not "Secrets"
- Verify endpoint URL format

### Build is slow (>15 minutes with cache)

This is expected for the first build. Subsequent builds should be faster:
- Check that caches are being hit (look for "Cache restored" in logs)
- mpy-cross and ESP-IDF caches are the biggest time savers
- Full clean builds will always be slow

## Comparison to GitLab CI

### Advantages
✅ Better caching (GitHub Actions cache is faster)  
✅ Native GitHub integration  
✅ Free for public repos  
✅ Better UI and logs  
✅ Workflow visualization  

### Differences
- GitLab: Uses `gitlab-ci.yml`  
- GitHub: Uses `.github/workflows/*.yml`
- GitLab: Artifact links in release  
- GitHub: Binary files attached to release
- GitLab: S3 upload in release job  
- GitHub: S3 upload in same workflow step

## Local Testing

You can test the build process locally using the same commands:

```bash
# Test version bump
make bump_version

# Test full release (without pushing)
make release

# Undo test release
git tag -d v0.0.2-abc1234
git reset --hard HEAD~1
```

See [docs/release_process.md](../docs/release_process.md) for detailed local testing guide.

## Monitoring

### Build Status Badge

Add this to your README.md to show build status:

```markdown
![Build Status](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/build.yml/badge.svg)
```

### Email Notifications

GitHub Actions automatically sends email notifications on:
- Workflow failures
- First workflow success after a failure

Configure in: Settings → Notifications → Actions

## Future Improvements

Potential enhancements:
- [ ] Add firmware size checks
- [ ] Run tests before building
- [ ] Build minimal firmware variant in parallel
- [ ] Matrix builds for multiple configurations
- [ ] Automated changelog generation
- [ ] Firmware signing for OTA security
- [ ] Deploy to staging environment for testing

## Support

For issues with the workflows:
1. Check the Actions tab for detailed logs
2. Review troubleshooting section above
3. See [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) for general issues
4. Open an issue with workflow run URL
