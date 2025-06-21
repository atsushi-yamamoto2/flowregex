#include "flowregex.h"
#include "optimized_text.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

// Test framework
static int tests_run = 0;
static int tests_passed = 0;

#define TEST(name) \
    static void test_##name(void); \
    static void run_test_##name(void) { \
        printf("Running test: %s... ", #name); \
        tests_run++; \
        test_##name(); \
        tests_passed++; \
        printf("PASSED\n"); \
    } \
    static void test_##name(void)

// Helper function to check match results
static bool check_match_result(match_result_t *result, int *expected, size_t expected_count) {
    if (!result && expected_count == 0) return true;
    if (!result || result->count != expected_count) return false;
    
    for (size_t i = 0; i < expected_count; i++) {
        bool found = false;
        for (size_t j = 0; j < result->count; j++) {
            if (result->positions[j] == expected[i]) {
                found = true;
                break;
            }
        }
        if (!found) return false;
    }
    return true;
}

// Test nested Kleene stars
TEST(nested_kleene_stars) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("(a*b)*", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    printf("\n--- Testing nested Kleene stars: (a*b)* ---\n");
    
    // Test empty string (should match at position 0)
    match_result_t *result1 = flowregex_match(regex, "", false);
    assert(result1 != NULL);
    int expected1[] = {0};
    assert(check_match_result(result1, expected1, 1));
    printf("Empty string: PASSED\n");
    match_result_destroy(result1);
    
    // Test "b" (should match at positions 0 and 1)
    match_result_t *result2 = flowregex_match(regex, "b", false);
    assert(result2 != NULL);
    printf("Text 'b' - Match count: %zu, Positions: ", result2->count);
    for (size_t i = 0; i < result2->count; i++) {
        printf("%d ", result2->positions[i]);
    }
    printf("\n");
    match_result_destroy(result2);
    
    // Test "abb" (should match at multiple positions)
    match_result_t *result3 = flowregex_match(regex, "abb", false);
    assert(result3 != NULL);
    printf("Text 'abb' - Match count: %zu, Positions: ", result3->count);
    for (size_t i = 0; i < result3->count; i++) {
        printf("%d ", result3->positions[i]);
    }
    printf("\n");
    match_result_destroy(result3);
    
    flowregex_destroy(regex);
}

// Test alternation with Kleene star
TEST(alternation_with_kleene) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("(a|b)*c", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    printf("\n--- Testing alternation with Kleene: (a|b)*c ---\n");
    
    // Test "c" (should match at position 1)
    match_result_t *result1 = flowregex_match(regex, "c", false);
    assert(result1 != NULL);
    int expected1[] = {1};
    assert(check_match_result(result1, expected1, 1));
    printf("Text 'c': PASSED\n");
    match_result_destroy(result1);
    
    // Test "abc" (should match at position 3)
    match_result_t *result2 = flowregex_match(regex, "abc", false);
    assert(result2 != NULL);
    int expected2[] = {3};
    assert(check_match_result(result2, expected2, 1));
    printf("Text 'abc': PASSED\n");
    match_result_destroy(result2);
    
    // Test "bababc" (should match at position 6)
    match_result_t *result3 = flowregex_match(regex, "bababc", false);
    assert(result3 != NULL);
    int expected3[] = {6};
    assert(check_match_result(result3, expected3, 1));
    printf("Text 'bababc': PASSED\n");
    match_result_destroy(result3);
    
    flowregex_destroy(regex);
}

// Test multiple quantifiers
TEST(multiple_quantifiers) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("a+b*c?", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    printf("\n--- Testing multiple quantifiers: a+b*c? ---\n");
    
    // Test "a" (should match at position 1)
    match_result_t *result1 = flowregex_match(regex, "a", false);
    assert(result1 != NULL);
    int expected1[] = {1};
    assert(check_match_result(result1, expected1, 1));
    printf("Text 'a': PASSED\n");
    match_result_destroy(result1);
    
    // Test "aab" (should match at positions 2 and 3)
    match_result_t *result2 = flowregex_match(regex, "aab", false);
    assert(result2 != NULL);
    printf("Text 'aab' - Match count: %zu, Positions: ", result2->count);
    for (size_t i = 0; i < result2->count; i++) {
        printf("%d ", result2->positions[i]);
    }
    printf("\n");
    match_result_destroy(result2);
    
    // Test "aabbc" (should match at positions 3, 4, and 5)
    match_result_t *result3 = flowregex_match(regex, "aabbc", false);
    assert(result3 != NULL);
    printf("Text 'aabbc' - Match count: %zu, Positions: ", result3->count);
    for (size_t i = 0; i < result3->count; i++) {
        printf("%d ", result3->positions[i]);
    }
    printf("\n");
    match_result_destroy(result3);
    
    flowregex_destroy(regex);
}

// Test deep recursion with complex pattern
TEST(deep_recursion) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("((a|b)*c)+d", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    printf("\n--- Testing deep recursion: ((a|b)*c)+d ---\n");
    
    // Test "cd" (should match at position 2)
    match_result_t *result1 = flowregex_match(regex, "cd", false);
    assert(result1 != NULL);
    int expected1[] = {2};
    assert(check_match_result(result1, expected1, 1));
    printf("Text 'cd': PASSED\n");
    match_result_destroy(result1);
    
    // Test "abccd" (should match at position 5)
    match_result_t *result2 = flowregex_match(regex, "abccd", false);
    assert(result2 != NULL);
    int expected2[] = {5};
    assert(check_match_result(result2, expected2, 1));
    printf("Text 'abccd': PASSED\n");
    match_result_destroy(result2);
    
    // Test "abcbaccd" (should match at position 8)
    match_result_t *result3 = flowregex_match(regex, "abcbaccd", false);
    assert(result3 != NULL);
    int expected3[] = {8};
    assert(check_match_result(result3, expected3, 1));
    printf("Text 'abcbaccd': PASSED\n");
    match_result_destroy(result3);
    
    flowregex_destroy(regex);
}

// Test edge cases with empty matches
TEST(empty_match_cases) {
    flowregex_error_t error;
    
    printf("\n--- Testing edge cases with empty matches ---\n");
    
    // Test a* (should match at every position)
    flowregex_t *regex1 = flowregex_create("a*", &error);
    assert(regex1 != NULL);
    assert(error == FLOWREGEX_OK);
    
    match_result_t *result1 = flowregex_match(regex1, "bbb", false);
    assert(result1 != NULL);
    printf("Pattern 'a*' on 'bbb' - Match count: %zu, Positions: ", result1->count);
    for (size_t i = 0; i < result1->count; i++) {
        printf("%d ", result1->positions[i]);
    }
    printf("\n");
    match_result_destroy(result1);
    flowregex_destroy(regex1);
    
    // Test (a|b)* (should match at every position)
    flowregex_t *regex2 = flowregex_create("(a|b)*", &error);
    assert(regex2 != NULL);
    assert(error == FLOWREGEX_OK);
    
    match_result_t *result2 = flowregex_match(regex2, "ab", false);
    assert(result2 != NULL);
    printf("Pattern '(a|b)*' on 'ab' - Match count: %zu, Positions: ", result2->count);
    for (size_t i = 0; i < result2->count; i++) {
        printf("%d ", result2->positions[i]);
    }
    printf("\n");
    match_result_destroy(result2);
    flowregex_destroy(regex2);
}

int main(void) {
    printf("=== FlowRegex Recursive Pattern Tests ===\n\n");
    
    // Run recursive pattern tests
    run_test_nested_kleene_stars();
    run_test_alternation_with_kleene();
    run_test_multiple_quantifiers();
    run_test_deep_recursion();
    run_test_empty_match_cases();
    
    printf("\n=== Test Results ===\n");
    printf("Tests run: %d\n", tests_run);
    printf("Tests passed: %d\n", tests_passed);
    
    if (tests_passed == tests_run) {
        printf("🎉 All recursive pattern tests passed!\n");
        return 0;
    } else {
        printf("❌ %d tests failed.\n", tests_run - tests_passed);
        return 1;
    }
}
