#!/bin/bash

#######################################
# Test Runner - Runs all tests
#######################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "Universal Bootstrapper - Test Suite"
echo "========================================="
echo ""

TOTAL_PASSED=0
TOTAL_FAILED=0

# Run unit tests
echo "Running Unit Tests..."
echo "-------------------------------------"

for test_file in "$SCRIPT_DIR"/unit/test_*.sh; do
    if [[ -f "$test_file" ]]; then
        echo ""
        echo "Running $(basename "$test_file")..."
        if bash "$test_file"; then
            TOTAL_PASSED=$((TOTAL_PASSED + 1))
        else
            TOTAL_FAILED=$((TOTAL_FAILED + 1))
        fi
    fi
done

echo ""
echo "-------------------------------------"
echo "Running Integration Tests..."
echo "-------------------------------------"

for test_file in "$SCRIPT_DIR"/integration/test_*.sh; do
    if [[ -f "$test_file" ]]; then
        echo ""
        echo "Running $(basename "$test_file")..."
        if bash "$test_file"; then
            TOTAL_PASSED=$((TOTAL_PASSED + 1))
        else
            TOTAL_FAILED=$((TOTAL_FAILED + 1))
        fi
    fi
done

echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "Total test suites passed: $TOTAL_PASSED"
echo "Total test suites failed: $TOTAL_FAILED"
echo "========================================="

if [[ $TOTAL_FAILED -gt 0 ]]; then
    echo "❌ Some tests failed"
    exit 1
else
    echo "✅ All tests passed!"
    exit 0
fi
