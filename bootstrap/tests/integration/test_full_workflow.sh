#!/bin/bash

#######################################
# Integration Test - Full Bootstrap Workflow
#######################################

set -euo pipefail

echo "========================================="
echo "Integration Test: Full Bootstrap Workflow"
echo "========================================="
echo ""

# Test configuration
TEST_REPO="https://github.com/spring-projects/spring-petclinic"
TEST_DIR="/tmp/bootstrap_integration_test_$$"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Cleanup function
cleanup() {
    echo ""
    echo "Cleaning up test environment..."
    rm -rf "$TEST_DIR"
}

trap cleanup EXIT

# Test steps
echo "1. Testing bootstrap.sh --help"
if ! "${SCRIPT_DIR}/bootstrap.sh" --help > /dev/null 2>&1; then
    echo "✗ FAIL: bootstrap.sh --help failed"
    exit 1
fi
echo "✓ PASS: bootstrap.sh --help works"

echo ""
echo "2. Testing repository cloning (without full bootstrap)"
# We'll test cloning only, not full deployment
if ! source "${SCRIPT_DIR}/lib/common.sh"; then
    echo "✗ FAIL: Could not source common.sh"
    exit 1
fi

if ! source "${SCRIPT_DIR}/lib/git.sh"; then
    echo "✗ FAIL: Could not source git.sh"
    exit 1
fi

echo "   Cloning test repository..."
if clone_repository "$TEST_REPO" "$TEST_DIR" > /dev/null 2>&1; then
    echo "✓ PASS: Repository cloned successfully"
else
    echo "✗ FAIL: Repository clone failed"
    exit 1
fi

echo ""
echo "3. Testing project detection"
if ! source "${SCRIPT_DIR}/lib/detect.sh"; then
    echo "✗ FAIL: Could not source detect.sh"
    exit 1
fi

PROJECT_TYPE=$(detect_project_type "$TEST_DIR")
echo "   Detected type: $PROJECT_TYPE"
if [[ "$PROJECT_TYPE" == "spring-boot" ]]; then
    echo "✓ PASS: Correctly detected Spring Boot project"
else
    echo "✗ FAIL: Expected spring-boot, got $PROJECT_TYPE"
    exit 1
fi

echo ""
echo "========================================="
echo "All integration tests passed!"
echo "========================================="

exit 0
