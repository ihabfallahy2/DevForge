#!/bin/bash

#######################################
# Unit Tests for lib/detect.sh
#######################################

set -euo pipefail

# Source the libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/detect.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

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

echo "Running tests for lib/detect.sh..."
echo ""

# Create test directories
TEST_DIR="/tmp/bootstrap_test_$$"
mkdir -p "$TEST_DIR"

# Test Spring Boot detection
mkdir -p "$TEST_DIR/spring-boot-test"
echo '<project><groupId>org.springframework.boot</groupId></project>' > "$TEST_DIR/spring-boot-test/pom.xml"
DETECTED=$(detect_project_type "$TEST_DIR/spring-boot-test")
assert_equals "spring-boot" "$DETECTED" "Detect Spring Boot from pom.xml"

# Test Node.js detection
mkdir -p "$TEST_DIR/nodejs-test"
echo '{"name": "test"}' > "$TEST_DIR/nodejs-test/package.json"
DETECTED=$(detect_project_type "$TEST_DIR/nodejs-test")
assert_equals "nodejs" "$DETECTED" "Detect Node.js from package.json"

# Test Python detection
mkdir -p "$TEST_DIR/python-test"
echo 'flask==2.0.0' > "$TEST_DIR/python-test/requirements.txt"
DETECTED=$(detect_project_type "$TEST_DIR/python-test")
assert_equals "python" "$DETECTED" "Detect Python from requirements.txt"

# Test Generic fallback
mkdir -p "$TEST_DIR/generic-test"
DETECTED=$(detect_project_type "$TEST_DIR/generic-test")
assert_equals "generic" "$DETECTED" "Fallback to generic for unknown projects"

# Cleanup
rm -rf "$TEST_DIR"

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
