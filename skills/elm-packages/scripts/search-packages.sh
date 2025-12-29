#!/bin/bash
# Search the Elm package registry
# Usage: search-packages.sh <query>
#
# Example: search-packages.sh "json decode"

set -eo pipefail

QUERY=""

for arg in "$@"; do
    [ -z "$QUERY" ] && QUERY="$arg"
done

if [ -z "$QUERY" ]; then
    echo "Usage: search-packages.sh <query>" >&2
    echo "Example: search-packages.sh \"json decode\"" >&2
    exit 1
fi

curl -sS --compressed "https://package.elm-lang.org/search.json" | \
    jq -r --arg q "$QUERY" '
        ($q | ascii_downcase) as $ql |
        [.[] | select((.name + " " + .summary) | ascii_downcase | contains($ql))]
        | sort_by(.name)
        | .[0:20]
        | "Search results for \"\($q)\" (\(length) packages):\n",
        (.[] | "\(.name) \(.version)\n  \(.summary)\n")
    '
