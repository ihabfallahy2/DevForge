#!/bin/bash

#######################################
# Unit Tests for lib/common.sh
#######################################

set -euo pipefail

# Source the library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test framework
assert_equals() {
    TESTS_RUN=$((TESTS_RUN + 1))
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_true() {
    TESTS_RUN=$((TESTS_RUN + 1))
    local test_name="$1"
    
    if eval "$2"; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Tests
echo "Running tests for lib/common.sh..."
echo ""

# Test check_command
assert_true "check_command with existing command (bash)" "check_command bash"
assert_true "check_command with non-existing command (fakecmd123)" "! check_command fakecmd123"

# Test detect_os
OS=$(detect_os)
assert_true "detect_os returns non-empty" "[[ -n '$OS' ]]"

# Test detect_shell
SHELL_TYPE=$(detect_shell)
assert_true "detect_shell returns bash or zsh" "[[ '$SHELL_TYPE' =~ bash|zsh ]]"

# Test validate_json (if jq available)
if check_command jq; then
    # Create temp test files
    echo '{"valid": "json"}' > /tmp/test_valid.json
    echo '{invalid json}' > /tmp/test_invalid.json
    
    assert_true "validate_json with valid JSON" "validate_json /tmp/test_valid.json"
    assert_true "validate_json with invalid JSON" "! validate_json /tmp/test_invalid.json"
    
    rm -f /tmp/test_valid.json /tmp/test_invalid.json
fi

# Test is_port_available
if check_command nc || check_command lsof; then
    # Assume port 9999 is available
    assert_true "is_port_available on unused port" "is_port_available 9999"
fi

# Summary
echo ""
echo "================================"
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "================================"

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
fi

exit 0
