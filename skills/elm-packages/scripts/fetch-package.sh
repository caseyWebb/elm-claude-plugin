#!/bin/bash
# Fetch Elm package documentation to local cache
# Usage: fetch-package.sh <author> <name> <version>
#
# Example: fetch-package.sh elm core 1.0.5

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
    echo "Usage: fetch-package.sh <author> <name> <version>" >&2
    echo "Example: fetch-package.sh elm core 1.0.5" >&2
    exit 1
fi

AUTHOR=$1
NAME=$2
VERSION=$3

validate_identifier "author" "$AUTHOR"
validate_identifier "name" "$NAME"
validate_identifier "version" "$VERSION"

CACHE_DIR="$HOME/.elm/0.19.1/packages/$AUTHOR/$NAME/$VERSION"
BASE_URL="https://package.elm-lang.org/packages/$AUTHOR/$NAME/$VERSION"

mkdir -p "$CACHE_DIR"

echo "Fetching $AUTHOR/$NAME@$VERSION..." >&2

# Fetch README
if curl -sSf --compressed "$BASE_URL/README.md" -o "$CACHE_DIR/README.md" 2>/dev/null; then
    echo "  README.md downloaded" >&2
else
    echo "  Warning: README.md not found" >&2
fi

# Fetch docs.json
if curl -sSf --compressed "$BASE_URL/docs.json" -o "$CACHE_DIR/docs.json" 2>/dev/null; then
    echo "  docs.json downloaded" >&2
else
    echo "  Error: docs.json not found" >&2
    exit 1
fi

echo "Cached to $CACHE_DIR"
