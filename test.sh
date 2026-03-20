#!/usr/bin/env bash
## Run all game tests (unit + E2E) headless.
## Usage: ./test.sh [--unit|--e2e|--all] [--verbose]
set -euo pipefail
cd "$(dirname "$0")"

GODOT="${GODOT_BIN:-/tmp/godot461/Godot_v4.6.1-stable_linux.x86_64}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse args
RUN_UNIT=false
RUN_E2E=false
VERBOSE=""

for arg in "$@"; do
    case "$arg" in
        --unit)   RUN_UNIT=true ;;
        --e2e)    RUN_E2E=true ;;
        --all)    RUN_UNIT=true; RUN_E2E=true ;;
        --verbose) VERBOSE="--verbose" ;;
        -h|--help)
            echo "Usage: ./test.sh [--unit|--e2e|--all] [--verbose]"
            echo "  --unit     Run unit tests only"
            echo "  --e2e      Run E2E tests only"
            echo "  --all      Run both (default)"
            echo "  --verbose  Show Godot engine output"
            exit 0
            ;;
    esac
done

# Default: run all
if ! $RUN_UNIT && ! $RUN_E2E; then
    RUN_UNIT=true
    RUN_E2E=true
fi

# Check Godot binary
if [ ! -f "$GODOT" ]; then
    echo -e "${RED}ERROR: Godot binary not found at: $GODOT${NC}"
    echo "Set GODOT_BIN env var to your Godot 4.6+ binary path."
    exit 1
fi

FAILED=0
TOTAL=0

run_test() {
    local name="$1"
    local script="$2"
    TOTAL=$((TOTAL + 1))

    echo ""
    echo -e "${YELLOW}▶ Running: ${name}${NC}"
    echo "────────────────────────────────"

    if [ -n "$VERBOSE" ]; then
        "$GODOT" --headless --script "$script" 2>&1
    else
        # Filter out engine noise, show only test output
        "$GODOT" --headless --script "$script" 2>&1 | grep -E "^(──|  [✓✗]|  ALL|  [0-9]|══)" || true
    fi

    local exit_code=${PIPESTATUS[0]}
    if [ "$exit_code" -ne 0 ]; then
        echo -e "${RED}✗ ${name}: FAILED (exit code $exit_code)${NC}"
        FAILED=$((FAILED + 1))
    else
        echo -e "${GREEN}✓ ${name}: PASSED${NC}"
    fi
}

echo "═══════════════════════════════════════"
echo "  7 Days Journey — Test Runner"
echo "═══════════════════════════════════════"

# Import resources first (needed for headless scene loading)
echo -e "${YELLOW}▶ Importing resources...${NC}"
"$GODOT" --headless --import 2>&1 | tail -1 || true

if $RUN_UNIT; then
    run_test "Unit Tests" "tests/test_runner.gd"
fi

if $RUN_E2E; then
    run_test "E2E Tests" "tests/test_e2e.gd"
fi

echo ""
echo "═══════════════════════════════════════"
if [ "$FAILED" -eq 0 ]; then
    echo -e "  ${GREEN}ALL $TOTAL TEST SUITES PASSED ✓${NC}"
else
    echo -e "  ${RED}$FAILED of $TOTAL TEST SUITES FAILED${NC}"
fi
echo "═══════════════════════════════════════"

exit $FAILED
