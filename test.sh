#!/bin/bash
# Automated test suite for elm-claude-plugin
# Usage: ./test.sh [-v|--verbose]

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$SCRIPT_DIR/skills/elm-packages/scripts"
TEST_DIR="$SCRIPT_DIR/test-fixture"
TEST_PKG_AUTHOR="elm"
TEST_PKG_NAME="json"
TEST_PKG_VERSION="1.1.3"
TEST_PKG_CACHE="$HOME/.elm/0.19.1/packages/$TEST_PKG_AUTHOR/$TEST_PKG_NAME/$TEST_PKG_VERSION"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASS=0
FAIL=0
SKIP=0
VERBOSE=false

for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=true ;;
    esac
done

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}  [verbose]${NC} $1"
    fi
}

# Test helper: expects success with pattern match
test_case() {
    local name="$1"
    local cmd="$2"
    local expected_pattern="$3"

    echo -n "  $name... "

    if output=$(eval "$cmd" 2>&1); then
        if echo "$output" | grep -q "$expected_pattern"; then
            echo -e "${GREEN}PASS${NC}"
            log_verbose "Output matched pattern: $expected_pattern"
            ((PASS++))
            return 0
        else
            echo -e "${RED}FAIL${NC} (pattern not found)"
            echo "    Expected pattern: $expected_pattern"
            echo "    Got: ${output:0:200}"
            ((FAIL++))
            return 1
        fi
    else
        echo -e "${RED}FAIL${NC} (command failed)"
        echo "    Command: $cmd"
        echo "    Output: ${output:0:200}"
        ((FAIL++))
        return 1
    fi
}

# Test helper: expects failure with pattern match in stderr
test_error_case() {
    local name="$1"
    local cmd="$2"
    local expected_pattern="$3"

    echo -n "  $name... "

    if output=$(eval "$cmd" 2>&1); then
        echo -e "${RED}FAIL${NC} (expected failure, got success)"
        echo "    Output: ${output:0:200}"
        ((FAIL++))
        return 1
    else
        if echo "$output" | grep -qi "$expected_pattern"; then
            echo -e "${GREEN}PASS${NC}"
            log_verbose "Error output matched pattern: $expected_pattern"
            ((PASS++))
            return 0
        else
            echo -e "${RED}FAIL${NC} (error pattern not found)"
            echo "    Expected pattern: $expected_pattern"
            echo "    Got: ${output:0:200}"
            ((FAIL++))
            return 1
        fi
    fi
}

# Test helper: expects empty output (for non-matching queries)
test_empty_output() {
    local name="$1"
    local cmd="$2"

    echo -n "  $name... "

    output=$(eval "$cmd" 2>&1)
    if [ -z "$output" ] || [ "$output" = "null" ]; then
        echo -e "${GREEN}PASS${NC}"
        log_verbose "Output was empty as expected"
        ((PASS++))
        return 0
    else
        echo -e "${RED}FAIL${NC} (expected empty output)"
        echo "    Got: ${output:0:200}"
        ((FAIL++))
        return 1
    fi
}

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║       elm-claude-plugin Test Suite                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Verify prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed${NC}"
    exit 1
fi
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed${NC}"
    exit 1
fi
if [ ! -d "$TEST_DIR" ]; then
    echo -e "${RED}Error: Test directory not found: $TEST_DIR${NC}"
    exit 1
fi
echo -e "${GREEN}Prerequisites OK${NC}"
echo ""

# Setup: clear test package cache to verify auto-fetch
echo -e "${BLUE}Setup: Clearing test package cache ($TEST_PKG_AUTHOR/$TEST_PKG_NAME@$TEST_PKG_VERSION)...${NC}"
rm -rf "$TEST_PKG_CACHE"
echo ""

# ═══════════════════════════════════════════════════════════════════
# 1. list-installed-packages.sh
# ═══════════════════════════════════════════════════════════════════
echo -e "${YELLOW}━━━ 1. list-installed-packages.sh ━━━${NC}"

cd "$TEST_DIR"

test_case "Plain text output" \
    "$SCRIPTS/list-installed-packages.sh" \
    "Direct dependencies"

test_error_case "Error: no elm.json" \
    "cd /tmp && $SCRIPTS/list-installed-packages.sh" \
    "elm.json not found"

echo ""

# ═══════════════════════════════════════════════════════════════════
# 2. search-packages.sh
# ═══════════════════════════════════════════════════════════════════
echo -e "${YELLOW}━━━ 2. search-packages.sh ━━━${NC}"

test_case "Plain text output" \
    "$SCRIPTS/search-packages.sh json" \
    "Search results"

test_case "Case insensitive" \
    "$SCRIPTS/search-packages.sh JSON" \
    "Search results"

test_error_case "Error: no query" \
    "$SCRIPTS/search-packages.sh" \
    "Usage"

echo ""

# ═══════════════════════════════════════════════════════════════════
# 3. get-exports.sh
# ═══════════════════════════════════════════════════════════════════
echo -e "${YELLOW}━━━ 3. get-exports.sh ━━━${NC}"

# First test verifies auto-fetch (cache was cleared in setup)

test_case "All modules (plain text)" \
    "$SCRIPTS/get-exports.sh $TEST_PKG_AUTHOR $TEST_PKG_NAME $TEST_PKG_VERSION" \
    "elm/json"

test_case "Single module (plain text)" \
    "$SCRIPTS/get-exports.sh $TEST_PKG_AUTHOR $TEST_PKG_NAME $TEST_PKG_VERSION Json.Decode" \
    "Module: Json.Decode"

test_empty_output "Module not found (no output)" \
    "$SCRIPTS/get-exports.sh $TEST_PKG_AUTHOR $TEST_PKG_NAME $TEST_PKG_VERSION NonExistent.Module"

test_error_case "Error: auto-fetch fails for invalid package" \
    "$SCRIPTS/get-exports.sh nonexistent fakepkg 1.0.0" \
    "Failed to fetch"

echo ""

# ═══════════════════════════════════════════════════════════════════
# 4. get-export-docs.sh
# ═══════════════════════════════════════════════════════════════════
echo -e "${YELLOW}━━━ 4. get-export-docs.sh ━━━${NC}"

# Package is already cached from get-exports.sh tests

test_case "Function docs (plain text)" \
    "$SCRIPTS/get-export-docs.sh $TEST_PKG_AUTHOR $TEST_PKG_NAME $TEST_PKG_VERSION Json.Decode map" \
    "map :"

test_case "Type docs" \
    "$SCRIPTS/get-export-docs.sh $TEST_PKG_AUTHOR $TEST_PKG_NAME $TEST_PKG_VERSION Json.Decode Decoder" \
    "type Decoder"

test_case "Alias docs" \
    "$SCRIPTS/get-export-docs.sh $TEST_PKG_AUTHOR $TEST_PKG_NAME $TEST_PKG_VERSION Json.Decode Value" \
    "type alias Value"

test_error_case "Error: export not found" \
    "$SCRIPTS/get-export-docs.sh $TEST_PKG_AUTHOR $TEST_PKG_NAME $TEST_PKG_VERSION Json.Decode nonexistent" \
    "not found"

echo ""

# ═══════════════════════════════════════════════════════════════════
# 5. get-readme.sh
# ═══════════════════════════════════════════════════════════════════
echo -e "${YELLOW}━━━ 5. get-readme.sh ━━━${NC}"

# Package is already cached from earlier tests

test_case "Read README" \
    "$SCRIPTS/get-readme.sh $TEST_PKG_AUTHOR $TEST_PKG_NAME $TEST_PKG_VERSION" \
    "Decode"

test_error_case "Error: missing arguments" \
    "$SCRIPTS/get-readme.sh elm" \
    "Usage"

test_error_case "Error: invalid package" \
    "$SCRIPTS/get-readme.sh nonexistent fakepkg 9.9.9" \
    "Failed to fetch"

echo ""

# ═══════════════════════════════════════════════════════════════════
# 6. fetch-package.sh
# ═══════════════════════════════════════════════════════════════════
echo -e "${YELLOW}━━━ 6. fetch-package.sh ━━━${NC}"

# Clear cache again for direct fetch tests
rm -rf "$TEST_PKG_CACHE"

test_case "Direct fetch" \
    "$SCRIPTS/fetch-package.sh $TEST_PKG_AUTHOR $TEST_PKG_NAME $TEST_PKG_VERSION" \
    "docs.json downloaded"

test_error_case "Error: missing arguments" \
    "$SCRIPTS/fetch-package.sh elm" \
    "Usage"

test_error_case "Error: invalid package" \
    "$SCRIPTS/fetch-package.sh nonexistent fakepkg 9.9.9" \
    "Error"

echo ""

# ═══════════════════════════════════════════════════════════════════
# 7. Security tests
# ═══════════════════════════════════════════════════════════════════
echo -e "${YELLOW}━━━ 7. Security tests ━━━${NC}"

# Path traversal attacks should be rejected
test_error_case "Reject path traversal in author" \
    "$SCRIPTS/fetch-package.sh '../../../tmp' test 1.0.0" \
    "Invalid author"

test_error_case "Reject path traversal in name" \
    "$SCRIPTS/get-exports.sh elm '../passwd' 1.0.0" \
    "Invalid name"

test_error_case "Reject path traversal in version" \
    "$SCRIPTS/get-export-docs.sh elm json '../../../etc' List map" \
    "Invalid version"

# Special characters in search should not crash (regex injection fix)
test_case "Search with special chars (brackets)" \
    "$SCRIPTS/search-packages.sh '[json]'" \
    "Search results"

test_case "Search with special chars (parens)" \
    "$SCRIPTS/search-packages.sh '(decode)'" \
    "Search results"

echo ""

# ═══════════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════════
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                        Test Results                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
TOTAL=$((PASS + FAIL + SKIP))
echo -e "  ${GREEN}Passed:${NC}  $PASS"
echo -e "  ${RED}Failed:${NC}  $FAIL"
if [ $SKIP -gt 0 ]; then
    echo -e "  ${YELLOW}Skipped:${NC} $SKIP"
fi
echo "  ─────────────"
echo "  Total:   $TOTAL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}$FAIL test(s) failed${NC}"
    exit 1
fi
