#include "flowregex.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// Match result functions
match_result_t *match_result_create(void) {
    match_result_t *result = malloc(sizeof(match_result_t));
    if (!result) return NULL;
    
    result->capacity = 16;
    result->count = 0;
    result->positions = malloc(result->capacity * sizeof(int));
    
    if (!result->positions) {
        free(result);
        return NULL;
    }
    
    return result;
}

void match_result_destroy(match_result_t *result) {
    if (result) {
        free(result->positions);
        free(result);
    }
}

void match_result_add(match_result_t *result, int position) {
    if (!result) return;
    
    // Resize if needed
    if (result->count >= result->capacity) {
        size_t new_capacity = result->capacity * 2;
        int *new_positions = realloc(result->positions, new_capacity * sizeof(int));
        if (!new_positions) return; // Failed to resize
        
        result->positions = new_positions;
        result->capacity = new_capacity;
    }
    
    result->positions[result->count++] = position;
}

// Main FlowRegex API
flowregex_t *flowregex_create(const char *pattern, flowregex_error_t *error) {
    if (!pattern || !error) {
        if (error) *error = FLOWREGEX_ERROR_INVALID_PATTERN;
        return NULL;
    }
    
    *error = FLOWREGEX_OK;
    
    flowregex_t *regex = malloc(sizeof(flowregex_t));
    if (!regex) {
        *error = FLOWREGEX_ERROR_MEMORY;
        return NULL;
    }
    
    regex->pattern = strdup(pattern);
    if (!regex->pattern) {
        free(regex);
        *error = FLOWREGEX_ERROR_MEMORY;
        return NULL;
    }
    
    regex->root = parse_regex(pattern, error);
    if (!regex->root) {
        free(regex->pattern);
        free(regex);
        return NULL;
    }
    
    return regex;
}

void flowregex_destroy(flowregex_t *regex) {
    if (regex) {
        free(regex->pattern);
        if (regex->root) {
            regex->root->destroy(regex->root);
        }
        free(regex);
    }
}

match_result_t *flowregex_match(flowregex_t *regex, const char *text, bool debug) {
    if (!regex || !text) return NULL;
    
    size_t text_len = strlen(text);
    if (text_len > FLOWREGEX_MAX_TEXT_LENGTH) {
        return NULL;
    }
    
    if (debug) {
        printf("=== FlowRegex Matching Debug ===\n");
        printf("Text: '%s'\n", text);
        printf("Pattern: %s\n", regex->pattern);
        printf("Initial mask: ");
    }
    
    // Create initial bitmask with all positions set (flow regex starts from every position)
    bitmask_t *initial_mask = bitmask_create(text_len + 1);
    if (!initial_mask) return NULL;
    
    for (size_t i = 0; i <= text_len; i++) {
        bitmask_set(initial_mask, i);
    }
    
    if (debug) {
        #ifdef DEBUG
        bitmask_print(initial_mask, "");
        #endif
        printf("\n");
    }
    
    // Apply the regex
    bitmask_t *result_mask = regex->root->apply(regex->root, initial_mask, text, debug, NULL);
    bitmask_destroy(initial_mask);
    
    if (!result_mask) return NULL;
    
    if (debug) {
        printf("Final result: ");
        #ifdef DEBUG
        bitmask_print(result_mask, "");
        #endif
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

// Utility functions
void flowregex_print_error(flowregex_error_t error) {
    printf("FlowRegex Error: %s\n", flowregex_error_string(error));
}

const char *flowregex_error_string(flowregex_error_t error) {
    switch (error) {
        case FLOWREGEX_OK:
            return "No error";
        case FLOWREGEX_ERROR_PARSE:
            return "Parse error";
        case FLOWREGEX_ERROR_MEMORY:
            return "Memory allocation error";
        case FLOWREGEX_ERROR_TEXT_TOO_LONG:
            return "Text too long";
        case FLOWREGEX_ERROR_INVALID_PATTERN:
            return "Invalid pattern";
        default:
            return "Unknown error";
    }
}
