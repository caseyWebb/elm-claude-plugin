#!/bin/bash
# Get README from an Elm package
# Usage: get-readme.sh <author> <name> <version>
#
# Example: get-readme.sh elm core 1.0.5

set -eo pipefail

# Validate that an identifier contains only safe characters (alphanumeric, dots, hyphens, underscores)
# This prevents path traversal attacks via malicious package names
validate_identifier() {
    local name="$1"
    local value="$2"
    if [[ ! "$value" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
        echo "Error: Invalid $name: $value" >&2
        exit 1
    fi
}

if [ $# -lt 3 ]; then
    echo "Usage: get-readme.sh <author> <name> <version>" >&2
    echo "Example: get-readme.sh elm core 1.0.5" >&2
    exit 1
fi

AUTHOR=$1
NAME=$2
VERSION=$3

validate_identifier "author" "$AUTHOR"
validate_identifier "name" "$NAME"
validate_identifier "version" "$VERSION"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE_DIR="$HOME/.elm/0.19.1/packages/$AUTHOR/$NAME/$VERSION"
README_FILE="$CACHE_DIR/README.md"

if [ ! -f "$README_FILE" ]; then
    # Auto-fetch the package (silently - output suppressed)
    if ! "$SCRIPT_DIR/fetch-package.sh" "$AUTHOR" "$NAME" "$VERSION" >/dev/null 2>&1; then
        echo "Error: Failed to fetch package $AUTHOR/$NAME@$VERSION" >&2
        exit 1
    fi
fi

if [ ! -f "$README_FILE" ]; then
    echo "Error: README not available for $AUTHOR/$NAME@$VERSION" >&2
    exit 1
fi

cat "$README_FILE"
