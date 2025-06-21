#!/bin/bash

echo "=== FlowRegex C Implementation - Complete Test Suite ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

total_tests=0
passed_tests=0

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}Running $test_name...${NC}"
    echo "----------------------------------------"
    
    if $test_command; then
        echo -e "${GREEN}✅ $test_name: PASSED${NC}"
        ((passed_tests++))
    else
        echo -e "${RED}❌ $test_name: FAILED${NC}"
    fi
    
    ((total_tests++))
    echo ""
}

# Run all test suites
run_test "Basic Test Suite" "./test_runner"
run_test "OptimizedText Tests" "./test_with_optimization"
run_test "Recursive Pattern Tests" "./test_recursive_patterns"

# Summary
echo "========================================"
echo "=== FINAL TEST RESULTS ==="
echo "========================================"
echo "Total test suites: $total_tests"
echo "Passed test suites: $passed_tests"

if [ $passed_tests -eq $total_tests ]; then
    echo -e "${GREEN}🎉 ALL TEST SUITES PASSED! 🎉${NC}"
    echo ""
    echo "✅ Basic functionality: WORKING"
    echo "✅ OptimizedText optimization: WORKING"
    echo "✅ Recursive patterns: WORKING"
    echo "✅ Complex nested patterns: WORKING"
    echo "✅ Edge cases: WORKING"
    echo ""
    echo "FlowRegex C implementation PoC validation completed successfully!"
    exit 0
else
    echo -e "${RED}❌ $((total_tests - passed_tests)) test suite(s) failed.${NC}"
    exit 1
fi
