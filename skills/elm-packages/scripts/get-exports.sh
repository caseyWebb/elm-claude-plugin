#!/bin/bash
# Get exports from an Elm package (without documentation comments)
# Usage: get-exports.sh <author> <name> <version> [module]
#
# Examples:
#   get-exports.sh elm core 1.0.5              # All modules overview
#   get-exports.sh elm core 1.0.5 List         # Single module exports

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

for arg in "$@"; do
    if [ -z "$AUTHOR" ]; then AUTHOR="$arg"
    elif [ -z "$NAME" ]; then NAME="$arg"
    elif [ -z "$VERSION" ]; then VERSION="$arg"
    elif [ -z "$MODULE" ]; then MODULE="$arg"
    fi
done

if [ -z "$AUTHOR" ] || [ -z "$NAME" ] || [ -z "$VERSION" ]; then
    echo "Usage: get-exports.sh <author> <name> <version> [module]" >&2
    echo "Examples:" >&2
    echo "  get-exports.sh elm core 1.0.5           # All modules" >&2
    echo "  get-exports.sh elm core 1.0.5 List      # Single module" >&2
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

if [ -n "$MODULE" ]; then
    # Single module exports (names only)
    jq -r --arg m "$MODULE" '
        .[] | select(.name == $m) |
        "Module: \(.name)\n",
        (if (.unions | length) > 0 then
            "Types:\n" + ([.unions[] | "  \(.name)"] | join("\n")) + "\n"
        else "" end),
        (if (.aliases | length) > 0 then
            "Aliases:\n" + ([.aliases[] | "  \(.name)"] | join("\n")) + "\n"
        else "" end),
        (if (.values | length) > 0 then
            "Functions:\n" + ([.values[] | "  \(.name)"] | join("\n"))
        else "" end),
        (if (.binops | length) > 0 then
            "\nOperators:\n" + ([.binops[] | "  (\(.name))"] | join("\n"))
        else "" end)
    ' "$DOCS_FILE"
else
    # All modules overview
    jq -r --arg pkg "$AUTHOR/$NAME" '
        "\($pkg) - \(length) modules\n",
        (.[] |
            "\(.name)",
            (if (.unions | length) > 0 then "  Types: \([.unions[].name] | join(", "))" else empty end),
            (if (.aliases | length) > 0 then "  Aliases: \([.aliases[].name] | join(", "))" else empty end),
            (if (.values | length) > 0 then "  Functions: \([.values[].name] | join(", "))" else empty end),
            (if (.binops | length) > 0 then "  Operators: \([.binops[].name] | join(", "))" else empty end),
            ""
        )
    ' "$DOCS_FILE"
fi
