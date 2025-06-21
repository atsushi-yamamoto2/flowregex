#include "flowregex.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void print_usage(const char *program_name) {
    printf("Usage: %s [options] <pattern> <text>\n", program_name);
    printf("Options:\n");
    printf("  -d, --debug    Enable debug output\n");
    printf("  -h, --help     Show this help message\n");
    printf("\nExamples:\n");
    printf("  %s \"abc\" \"xabcyz\"        # Basic literal matching\n", program_name);
    printf("  %s \"a*b\" \"aaab\"          # Kleene star\n", program_name);
    printf("  %s \"a|b\" \"cat\"           # Alternation\n", program_name);
    printf("  %s \"\\\\d+\" \"abc123def\"    # Character classes\n", program_name);
    printf("  %s -d \"a+\" \"aaa\"         # Debug mode\n", program_name);
}

void print_match_result(match_result_t *result) {
    if (!result || result->count == 0) {
        printf("No matches found.\n");
        return;
    }
    
    printf("Match end positions: [");
    for (size_t i = 0; i < result->count; i++) {
        if (i > 0) printf(", ");
        printf("%d", result->positions[i]);
    }
    printf("]\n");
}

int main(int argc, char *argv[]) {
    bool debug = false;
    const char *pattern = NULL;
    const char *text = NULL;
    
    // Parse command line arguments
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-d") == 0 || strcmp(argv[i], "--debug") == 0) {
            debug = true;
        } else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
            print_usage(argv[0]);
            return 0;
        } else if (!pattern) {
            pattern = argv[i];
        } else if (!text) {
            text = argv[i];
        } else {
            fprintf(stderr, "Too many arguments.\n");
            print_usage(argv[0]);
            return 1;
        }
    }
    
    if (!pattern || !text) {
        fprintf(stderr, "Missing required arguments.\n");
        print_usage(argv[0]);
        return 1;
    }
    
    // Create FlowRegex
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create(pattern, &error);
    
    if (!regex) {
        fprintf(stderr, "Failed to create regex: %s\n", flowregex_error_string(error));
        return 1;
    }
    
    printf("Pattern: %s\n", pattern);
    printf("Text: %s\n", text);
    printf("\n");
    
    // Perform matching
    match_result_t *result = flowregex_match(regex, text, debug);
    
    if (!result) {
        fprintf(stderr, "Matching failed.\n");
        flowregex_destroy(regex);
        return 1;
    }
    
    // Print results
    print_match_result(result);
    
    // Cleanup
    match_result_destroy(result);
    flowregex_destroy(regex);
    
    return 0;
}
