#!/bin/bash
# List installed Elm packages from elm.json
# Usage: list-installed-packages.sh
#
# Searches up from current directory to find elm.json

set -eo pipefail

# Find elm.json by searching up the directory tree
find_elm_json() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/elm.json" ]; then
            echo "$dir/elm.json"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

ELM_JSON=$(find_elm_json) || {
    echo "Error: elm.json not found in current directory or any parent" >&2
    exit 1
}

jq -r '
    "Direct dependencies (\(.dependencies.direct | length)):",
    (.dependencies.direct | to_entries | sort_by(.key)[] | "  \(.key) \(.value)")
' "$ELM_JSON"
