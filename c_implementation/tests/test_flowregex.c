#include "flowregex.h"
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

// Test basic literal matching
TEST(literal_matching) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("abc", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    printf("\n--- Debug literal matching ---\n");
    match_result_t *result = flowregex_match(regex, "xabcyz", true);
    assert(result != NULL);
    
    printf("Match result count: %zu\n", result->count);
    if (result->count > 0) {
        printf("Positions: ");
        for (size_t i = 0; i < result->count; i++) {
            printf("%d ", result->positions[i]);
        }
        printf("\n");
    } else {
        printf("No matches found\n");
    }
    
    int expected[] = {4};
    assert(check_match_result(result, expected, 1));
    
    match_result_destroy(result);
    flowregex_destroy(regex);
}

// Test alternation
TEST(alternation) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("a|b", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    printf("\n--- Debug alternation ---\n");
    match_result_t *result = flowregex_match(regex, "cat", true);
    assert(result != NULL);
    
    printf("Match result count: %zu\n", result->count);
    if (result->count > 0) {
        printf("Positions: ");
        for (size_t i = 0; i < result->count; i++) {
            printf("%d ", result->positions[i]);
        }
        printf("\n");
    } else {
        printf("No matches found\n");
    }
    
    int expected[] = {2};
    assert(check_match_result(result, expected, 1));
    
    match_result_destroy(result);
    flowregex_destroy(regex);
}

// Test Kleene star
TEST(kleene_star) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("a*b", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    printf("\n--- Debug kleene star ---\n");
    match_result_t *result = flowregex_match(regex, "aaab", true);
    assert(result != NULL);
    
    printf("Match result count: %zu\n", result->count);
    if (result->count > 0) {
        printf("Positions: ");
        for (size_t i = 0; i < result->count; i++) {
            printf("%d ", result->positions[i]);
        }
        printf("\n");
    } else {
        printf("No matches found\n");
    }
    
    int expected[] = {4};
    assert(check_match_result(result, expected, 1));
    
    match_result_destroy(result);
    flowregex_destroy(regex);
}

// Test plus quantifier
TEST(plus_quantifier) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("a+", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    match_result_t *result = flowregex_match(regex, "aaa", false);
    assert(result != NULL);
    
    int expected[] = {1, 2, 3};
    assert(check_match_result(result, expected, 3));
    
    match_result_destroy(result);
    flowregex_destroy(regex);
}

// Test question quantifier
TEST(question_quantifier) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("a?b", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    printf("\n--- Debug question quantifier ---\n");
    match_result_t *result = flowregex_match(regex, "ab", true);
    assert(result != NULL);
    
    printf("Match result count: %zu\n", result->count);
    if (result->count > 0) {
        printf("Positions: ");
        for (size_t i = 0; i < result->count; i++) {
            printf("%d ", result->positions[i]);
        }
        printf("\n");
    } else {
        printf("No matches found\n");
    }
    
    int expected[] = {2};
    assert(check_match_result(result, expected, 1));
    
    match_result_destroy(result);
    flowregex_destroy(regex);
}

// Test any character
TEST(any_character) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("a.c", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    match_result_t *result = flowregex_match(regex, "abc", false);
    assert(result != NULL);
    
    int expected[] = {3};
    assert(check_match_result(result, expected, 1));
    
    match_result_destroy(result);
    flowregex_destroy(regex);
}

// Test character classes
TEST(character_classes) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("\\d+", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    match_result_t *result = flowregex_match(regex, "abc123def", false);
    assert(result != NULL);
    
    int expected[] = {4, 5, 6};
    assert(check_match_result(result, expected, 3));
    
    match_result_destroy(result);
    flowregex_destroy(regex);
}

// Test grouping
TEST(grouping) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("(ab)+", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    match_result_t *result = flowregex_match(regex, "ababab", false);
    assert(result != NULL);
    
    int expected[] = {2, 4, 6};
    assert(check_match_result(result, expected, 3));
    
    match_result_destroy(result);
    flowregex_destroy(regex);
}

// Test complex pattern
TEST(complex_pattern) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("a(b|c)*d", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    printf("\n--- Debug complex pattern ---\n");
    match_result_t *result = flowregex_match(regex, "abcbcd", true);
    assert(result != NULL);
    
    printf("Match result count: %zu\n", result->count);
    if (result->count > 0) {
        printf("Positions: ");
        for (size_t i = 0; i < result->count; i++) {
            printf("%d ", result->positions[i]);
        }
        printf("\n");
    } else {
        printf("No matches found\n");
    }
    
    int expected[] = {6};
    assert(check_match_result(result, expected, 1));
    
    match_result_destroy(result);
    flowregex_destroy(regex);
}

// Test error handling
TEST(error_handling) {
    flowregex_error_t error;
    
    // Invalid pattern
    flowregex_t *regex = flowregex_create("(abc", &error);
    assert(regex == NULL);
    assert(error == FLOWREGEX_ERROR_PARSE);
    
    // Empty pattern
    regex = flowregex_create("", &error);
    assert(regex == NULL);
    assert(error == FLOWREGEX_ERROR_INVALID_PATTERN);
    
    // NULL pattern
    regex = flowregex_create(NULL, &error);
    assert(regex == NULL);
    assert(error == FLOWREGEX_ERROR_INVALID_PATTERN);
}

// Test bitmask operations
TEST(bitmask_operations) {
    bitmask_t *mask1 = bitmask_create(10);
    bitmask_t *mask2 = bitmask_create(10);
    
    assert(mask1 != NULL);
    assert(mask2 != NULL);
    
    // Test set and get
    bitmask_set(mask1, 3);
    bitmask_set(mask1, 7);
    assert(bitmask_get(mask1, 3) == true);
    assert(bitmask_get(mask1, 7) == true);
    assert(bitmask_get(mask1, 5) == false);
    
    // Test OR operation
    bitmask_set(mask2, 5);
    bitmask_or(mask1, mask2);
    assert(bitmask_get(mask1, 3) == true);
    assert(bitmask_get(mask1, 5) == true);
    assert(bitmask_get(mask1, 7) == true);
    
    // Test copy
    bitmask_t *mask3 = bitmask_copy(mask1);
    assert(mask3 != NULL);
    assert(bitmask_get(mask3, 3) == true);
    assert(bitmask_get(mask3, 5) == true);
    assert(bitmask_get(mask3, 7) == true);
    
    bitmask_destroy(mask1);
    bitmask_destroy(mask2);
    bitmask_destroy(mask3);
}

int main(void) {
    printf("=== FlowRegex C Implementation Tests ===\n\n");
    
    // Run all tests
    run_test_literal_matching();
    run_test_alternation();
    run_test_kleene_star();
    run_test_plus_quantifier();
    run_test_question_quantifier();
    run_test_any_character();
    run_test_character_classes();
    run_test_grouping();
    run_test_complex_pattern();
    run_test_error_handling();
    run_test_bitmask_operations();
    
    printf("\n=== Test Results ===\n");
    printf("Tests run: %d\n", tests_run);
    printf("Tests passed: %d\n", tests_passed);
    
    if (tests_passed == tests_run) {
        printf("🎉 All tests passed!\n");
        return 0;
    } else {
        printf("❌ %d tests failed.\n", tests_run - tests_passed);
        return 1;
    }
}
