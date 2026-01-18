#!/bin/bash
set -e

# Script to bump version in frozen_fs/VERSION
# Usage: ./scripts/bump_version.sh [major|minor|patch]

VERSION_FILE="frozen_fs/VERSION"
BUMP_TYPE="${1:-patch}"  # Default to patch if not specified

if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: VERSION file not found at $VERSION_FILE"
    exit 1
fi

# Read current version and remove any prefix (v) and suffix (-DEV)
CURRENT_VERSION=$(cat "$VERSION_FILE" | sed 's/^v//' | sed 's/-DEV$//')

# Split version into components
IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]:-0}"
MINOR="${VERSION_PARTS[1]:-0}"
PATCH="${VERSION_PARTS[2]:-1}"

# Bump version based on type
case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "Error: Invalid bump type '$BUMP_TYPE'. Use major, minor, or patch."
        exit 1
        ;;
esac

NEW_VERSION="v${MAJOR}.${MINOR}.${PATCH}"

echo "Current version: v${CURRENT_VERSION}"
echo "New version: ${NEW_VERSION}"

# Write new version to file
echo "$NEW_VERSION" > "$VERSION_FILE"

echo "Version updated successfully!"
echo "$NEW_VERSION"
