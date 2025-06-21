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

// Modified flowregex_match function that uses OptimizedText
match_result_t *flowregex_match_optimized(flowregex_t *regex, const char *text, bool debug) {
    if (!regex || !text) return NULL;
    
    size_t text_len = strlen(text);
    if (text_len > FLOWREGEX_MAX_TEXT_LENGTH) {
        return NULL;
    }
    
    if (debug) {
        printf("=== FlowRegex Matching Debug (Optimized) ===\n");
        printf("Text: '%s'\n", text);
        printf("Pattern: %s\n", regex->pattern);
        printf("Initial mask: ");
    }
    
    // Create OptimizedText
    optimized_text_t *opt_text = optimized_text_create(text, regex->pattern);
    
    // Create initial bitmask with all positions set
    bitmask_t *initial_mask = bitmask_create(text_len + 1);
    if (!initial_mask) {
        if (opt_text) optimized_text_destroy(opt_text);
        return NULL;
    }
    
    for (size_t i = 0; i <= text_len; i++) {
        bitmask_set(initial_mask, i);
    }
    
    if (debug) {
        printf("\n");
    }
    
    // Apply the regex with OptimizedText
    bitmask_t *result_mask = regex->root->apply(regex->root, initial_mask, text, debug, opt_text);
    bitmask_destroy(initial_mask);
    if (opt_text) optimized_text_destroy(opt_text);
    
    if (!result_mask) return NULL;
    
    if (debug) {
        printf("Final result: ");
        printf("\n=== End Debug ===\n");
    }
    
    // Convert bitmask to match result
    match_result_t *match_result = match_result_create();
    if (!match_result) {
        bitmask_destroy(result_mask);
        return NULL;
    }
    
    size_t count;
    int *positions = bitmask_get_set_positions(result_mask, &count);
    if (positions) {
        for (size_t i = 0; i < count; i++) {
            match_result_add(match_result, positions[i]);
        }
        free(positions);
    }
    
    bitmask_destroy(result_mask);
    return match_result;
}

// Test basic literal matching with optimization
TEST(literal_matching_optimized) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("abc", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    printf("\n--- Debug literal matching (optimized) ---\n");
    match_result_t *result = flowregex_match_optimized(regex, "xabcyz", true);
    assert(result != NULL);
    
    printf("Match result count: %zu\n", result->count);
    if (result->count > 0) {
        printf("Positions: ");
        for (size_t i = 0; i < result->count; i++) {
            printf("%d ", result->positions[i]);
        }
        printf("\n");
    }
    
    int expected[] = {4};
    assert(check_match_result(result, expected, 1));
    
    match_result_destroy(result);
    flowregex_destroy(regex);
}

// Test Kleene star with optimization
TEST(kleene_star_optimized) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("a*b", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    printf("\n--- Debug kleene star (optimized) ---\n");
    match_result_t *result = flowregex_match_optimized(regex, "aaab", true);
    assert(result != NULL);
    
    printf("Match result count: %zu\n", result->count);
    if (result->count > 0) {
        printf("Positions: ");
        for (size_t i = 0; i < result->count; i++) {
            printf("%d ", result->positions[i]);
        }
        printf("\n");
    }
    
    int expected[] = {4};
    assert(check_match_result(result, expected, 1));
    
    match_result_destroy(result);
    flowregex_destroy(regex);
}

// Test complex pattern with optimization
TEST(complex_pattern_optimized) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("a(b|c)*d", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    printf("\n--- Debug complex pattern (optimized) ---\n");
    match_result_t *result = flowregex_match_optimized(regex, "abcbcd", true);
    assert(result != NULL);
    
    printf("Match result count: %zu\n", result->count);
    if (result->count > 0) {
        printf("Positions: ");
        for (size_t i = 0; i < result->count; i++) {
            printf("%d ", result->positions[i]);
        }
        printf("\n");
    }
    
    int expected[] = {6};
    assert(check_match_result(result, expected, 1));
    
    match_result_destroy(result);
    flowregex_destroy(regex);
}

// Comparison test: same pattern with and without optimization
TEST(optimization_comparison) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create("ab+c", &error);
    assert(regex != NULL);
    assert(error == FLOWREGEX_OK);
    
    const char *test_text = "abbbc";
    
    // Test without optimization
    match_result_t *result_normal = flowregex_match(regex, test_text, false);
    assert(result_normal != NULL);
    
    // Test with optimization
    match_result_t *result_optimized = flowregex_match_optimized(regex, test_text, false);
    assert(result_optimized != NULL);
    
    // Results should be identical
    assert(result_normal->count == result_optimized->count);
    for (size_t i = 0; i < result_normal->count; i++) {
        bool found = false;
        for (size_t j = 0; j < result_optimized->count; j++) {
            if (result_normal->positions[i] == result_optimized->positions[j]) {
                found = true;
                break;
            }
        }
        assert(found);
    }
    
    printf("Normal result count: %zu, Optimized result count: %zu\n", 
           result_normal->count, result_optimized->count);
    
    match_result_destroy(result_normal);
    match_result_destroy(result_optimized);
    flowregex_destroy(regex);
}

int main(void) {
    printf("=== FlowRegex C Implementation Tests (With Optimization) ===\n\n");
    
    // Run optimization-specific tests
    run_test_literal_matching_optimized();
    run_test_kleene_star_optimized();
    run_test_complex_pattern_optimized();
    run_test_optimization_comparison();
    
    printf("\n=== Test Results ===\n");
    printf("Tests run: %d\n", tests_run);
    printf("Tests passed: %d\n", tests_passed);
    
    if (tests_passed == tests_run) {
        printf("🎉 All optimization tests passed!\n");
        return 0;
    } else {
        printf("❌ %d tests failed.\n", tests_run - tests_passed);
        return 1;
    }
}
