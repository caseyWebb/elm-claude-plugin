#!/bin/bash
# Get detailed documentation for a specific export
# Usage: get-export-docs.sh <author> <name> <version> <module> <export_name>
#
# Example: get-export-docs.sh elm core 1.0.5 List map

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

AUTHOR=""
NAME=""
VERSION=""
MODULE=""
EXPORT=""

for arg in "$@"; do
    if [ -z "$AUTHOR" ]; then AUTHOR="$arg"
    elif [ -z "$NAME" ]; then NAME="$arg"
    elif [ -z "$VERSION" ]; then VERSION="$arg"
    elif [ -z "$MODULE" ]; then MODULE="$arg"
    elif [ -z "$EXPORT" ]; then EXPORT="$arg"
    fi
done

if [ -z "$AUTHOR" ] || [ -z "$NAME" ] || [ -z "$VERSION" ] || [ -z "$MODULE" ] || [ -z "$EXPORT" ]; then
    echo "Usage: get-export-docs.sh <author> <name> <version> <module> <export_name>" >&2
    echo "Example: get-export-docs.sh elm core 1.0.5 List map" >&2
    exit 1
fi

validate_identifier "author" "$AUTHOR"
validate_identifier "name" "$NAME"
validate_identifier "version" "$VERSION"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE_DIR="$HOME/.elm/0.19.1/packages/$AUTHOR/$NAME/$VERSION"
DOCS_FILE="$CACHE_DIR/docs.json"

if [ ! -f "$DOCS_FILE" ]; then
    # Auto-fetch the package (silently - output suppressed)
    if ! "$SCRIPT_DIR/fetch-package.sh" "$AUTHOR" "$NAME" "$VERSION" >/dev/null 2>&1; then
        echo "Error: Failed to fetch package $AUTHOR/$NAME@$VERSION" >&2
        exit 1
    fi
fi

RESULT=$(jq -r --arg m "$MODULE" --arg e "$EXPORT" '
    .[] | select(.name == $m) |
    (
        (.values[] | select(.name == $e) | "\(.name) : \(.type)\n\n\(.comment)") //
        (.unions[] | select(.name == $e) | "type \(.name)\(if (.args | length) > 0 then " " + (.args | join(" ")) else "" end)\n\n\(.comment)") //
        (.aliases[] | select(.name == $e) | "type alias \(.name)\(if (.args | length) > 0 then " " + (.args | join(" ")) else "" end) =\n    \(.type)\n\n\(.comment)") //
        (.binops[] | select(.name == $e) | "(\(.name)) : \(.type)\n\nAssociativity: \(.associativity), Precedence: \(.precedence)\n\n\(.comment)")
    ) // empty
' "$DOCS_FILE")

if [ -z "$RESULT" ]; then
    echo "Error: Export '$EXPORT' not found in module '$MODULE'" >&2
    exit 1
else
    echo "$RESULT"
fi
