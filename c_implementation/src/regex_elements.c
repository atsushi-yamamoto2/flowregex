#include "flowregex.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>

// Forward declarations for apply functions
static bitmask_t *literal_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text);
static bitmask_t *concat_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text);
static bitmask_t *alternation_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text);
static bitmask_t *kleene_star_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text);
static bitmask_t *plus_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text);
static bitmask_t *question_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text);
static bitmask_t *any_char_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text);
static bitmask_t *char_class_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text);

// Forward declarations for destroy functions
static void literal_destroy(regex_element_t *self);
static void concat_destroy(regex_element_t *self);
static void alternation_destroy(regex_element_t *self);
static void kleene_star_destroy(regex_element_t *self);
static void plus_destroy(regex_element_t *self);
static void question_destroy(regex_element_t *self);
static void any_char_destroy(regex_element_t *self);
static void char_class_destroy(regex_element_t *self);

// Literal element
regex_element_t *literal_create(char c) {
    regex_element_t *elem = malloc(sizeof(regex_element_t));
    if (!elem) return NULL;
    
    literal_data_t *data = malloc(sizeof(literal_data_t));
    if (!data) {
        free(elem);
        return NULL;
    }
    
    data->character = c;
    
    elem->type = REGEX_LITERAL;
    elem->data = data;
    elem->left = NULL;
    elem->right = NULL;
    elem->apply = literal_apply;
    elem->destroy = literal_destroy;
    
    return elem;
}

static bitmask_t *literal_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text) {
    if (!self || !input || !text) return NULL;
    
    literal_data_t *data = (literal_data_t *)self->data;
    size_t text_len = strlen(text);
    bitmask_t *output = bitmask_create(input->size);
    if (!output) return NULL;
    
    if (debug) {
        printf("Literal '%c':\n", data->character);
        printf("  Input:  ");
        #ifdef DEBUG
        bitmask_print(input, "");
        #endif
    }
    
    // Use OptimizedText if available
    if (opt_text) {
        struct bitmask *char_mask = optimized_text_get_match_mask(opt_text, data->character);
        if (char_mask) {
            // Optimized path: direct word-level operations
            // This is the true optimization - operate on 64-bit words directly
            size_t words = input->capacity < char_mask->capacity ? input->capacity : char_mask->capacity;
            
            for (size_t word_idx = 0; word_idx < words; word_idx++) {
                uint64_t input_word = input->bits[word_idx];
                uint64_t char_word = char_mask->bits[word_idx];
                
                if (input_word == 0) continue;
                
                // For each bit set in input_word, check if next position has character
                for (int bit = 0; bit < 64 && word_idx * 64 + bit < input->size - 1; bit++) {
                    if (input_word & (1ULL << bit)) {
                        size_t pos = word_idx * 64 + bit;
                        if (pos < char_mask->size && bitmask_get(char_mask, pos)) {
                            if (pos + 1 < output->size) {
                                bitmask_set(output, pos + 1);
                            }
                        }
                    }
                }
            }
        } else {
            // Fallback to traditional method
            size_t count;
            int *positions = bitmask_get_set_positions(input, &count);
            if (positions) {
                for (size_t i = 0; i < count; i++) {
                    int pos = positions[i];
                    if (pos < (int)text_len && text[pos] == data->character) {
                        bitmask_set(output, pos + 1);
                    }
                }
                free(positions);
            }
        }
    } else {
        // Traditional path: character-by-character comparison
        size_t count;
        int *positions = bitmask_get_set_positions(input, &count);
        if (positions) {
            for (size_t i = 0; i < count; i++) {
                int pos = positions[i];
                if (pos < (int)text_len && text[pos] == data->character) {
                    bitmask_set(output, pos + 1);
                }
            }
            free(positions);
        }
    }
    
    if (debug) {
        printf("  Output: ");
        #ifdef DEBUG
        bitmask_print(output, "");
        #endif
        printf("\n");
    }
    
    return output;
}

static void literal_destroy(regex_element_t *self) {
    if (self) {
        free(self->data);
        free(self);
    }
}

// Concatenation element
regex_element_t *concat_create(regex_element_t *left, regex_element_t *right) {
    regex_element_t *elem = malloc(sizeof(regex_element_t));
    if (!elem) return NULL;
    
    elem->type = REGEX_CONCAT;
    elem->data = NULL;
    elem->left = left;
    elem->right = right;
    elem->apply = concat_apply;
    elem->destroy = concat_destroy;
    
    return elem;
}

static bitmask_t *concat_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text) {
    if (!self || !input || !text) return NULL;
    
    if (debug) {
        printf("Concat:\n");
    }
    
    // Apply left element first
    bitmask_t *intermediate = self->left->apply(self->left, input, text, debug, opt_text);
    if (!intermediate) return NULL;
    
    // Apply right element to the result
    bitmask_t *output = self->right->apply(self->right, intermediate, text, debug, opt_text);
    
    bitmask_destroy(intermediate);
    return output;
}

static void concat_destroy(regex_element_t *self) {
    if (self) {
        if (self->left) self->left->destroy(self->left);
        if (self->right) self->right->destroy(self->right);
        free(self);
    }
}

// Alternation element
regex_element_t *alternation_create(regex_element_t *left, regex_element_t *right) {
    regex_element_t *elem = malloc(sizeof(regex_element_t));
    if (!elem) return NULL;
    
    elem->type = REGEX_ALTERNATION;
    elem->data = NULL;
    elem->left = left;
    elem->right = right;
    elem->apply = alternation_apply;
    elem->destroy = alternation_destroy;
    
    return elem;
}

static bitmask_t *alternation_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text) {
    if (!self || !input || !text) return NULL;
    
    if (debug) {
        printf("Alternation:\n");
    }
    
    // Apply both branches
    bitmask_t *left_result = self->left->apply(self->left, input, text, debug, opt_text);
    bitmask_t *right_result = self->right->apply(self->right, input, text, debug, opt_text);
    
    if (!left_result || !right_result) {
        bitmask_destroy(left_result);
        bitmask_destroy(right_result);
        return NULL;
    }
    
    // Combine results with OR
    bitmask_or(left_result, right_result);
    
    bitmask_destroy(right_result);
    return left_result;
}

static void alternation_destroy(regex_element_t *self) {
    if (self) {
        if (self->left) self->left->destroy(self->left);
        if (self->right) self->right->destroy(self->right);
        free(self);
    }
}

// Kleene Star element
regex_element_t *kleene_star_create(regex_element_t *inner) {
    regex_element_t *elem = malloc(sizeof(regex_element_t));
    if (!elem) return NULL;
    
    elem->type = REGEX_KLEENE_STAR;
    elem->data = NULL;
    elem->left = inner;
    elem->right = NULL;
    elem->apply = kleene_star_apply;
    elem->destroy = kleene_star_destroy;
    
    return elem;
}

static bitmask_t *kleene_star_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text) {
    if (!self || !input || !text) return NULL;
    
    if (debug) {
        printf("Kleene Star:\n");
    }
    
    bitmask_t *result = bitmask_copy(input);
    if (!result) return NULL;
    
    bitmask_t *current = bitmask_copy(input);
    if (!current) {
        bitmask_destroy(result);
        return NULL;
    }
    
    // Iterate until convergence
    for (int iteration = 0; iteration < 100; iteration++) { // Prevent infinite loops
        bitmask_t *next = self->left->apply(self->left, current, text, debug, opt_text);
        if (!next) break;
        
        // Check if we have new bits
        bitmask_t *temp = bitmask_copy(result);
        if (!temp) {
            bitmask_destroy(next);
            break;
        }
        
        bitmask_or(result, next);
        
        // Check for convergence
        bool converged = true;
        for (size_t i = 0; i < result->size; i++) {
            if (bitmask_get(result, i) != bitmask_get(temp, i)) {
                converged = false;
                break;
            }
        }
        
        bitmask_destroy(temp);
        bitmask_destroy(current);
        current = next;
        
        if (converged) break;
    }
    
    bitmask_destroy(current);
    return result;
}

static void kleene_star_destroy(regex_element_t *self) {
    if (self) {
        if (self->left) self->left->destroy(self->left);
        free(self);
    }
}

// Plus element (one or more)
regex_element_t *plus_create(regex_element_t *inner) {
    regex_element_t *elem = malloc(sizeof(regex_element_t));
    if (!elem) return NULL;
    
    elem->type = REGEX_PLUS;
    elem->data = NULL;
    elem->left = inner;
    elem->right = NULL;
    elem->apply = plus_apply;
    elem->destroy = plus_destroy;
    
    return elem;
}

static bitmask_t *plus_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text) {
    if (!self || !input || !text) return NULL;
    
    if (debug) {
        printf("Plus:\n");
    }
    
    // First application (required)
    bitmask_t *result = self->left->apply(self->left, input, text, debug, opt_text);
    if (!result) return NULL;
    
    bitmask_t *current = bitmask_copy(result);
    if (!current) {
        bitmask_destroy(result);
        return NULL;
    }
    
    // Continue applying until convergence
    for (int iteration = 0; iteration < 100; iteration++) {
        bitmask_t *next = self->left->apply(self->left, current, text, debug, opt_text);
        if (!next) break;
        
        bitmask_t *temp = bitmask_copy(result);
        if (!temp) {
            bitmask_destroy(next);
            break;
        }
        
        bitmask_or(result, next);
        
        // Check for convergence
        bool converged = true;
        for (size_t i = 0; i < result->size; i++) {
            if (bitmask_get(result, i) != bitmask_get(temp, i)) {
                converged = false;
                break;
            }
        }
        
        bitmask_destroy(temp);
        bitmask_destroy(current);
        current = next;
        
        if (converged) break;
    }
    
    bitmask_destroy(current);
    return result;
}

static void plus_destroy(regex_element_t *self) {
    if (self) {
        if (self->left) self->left->destroy(self->left);
        free(self);
    }
}

// Question element (zero or one)
regex_element_t *question_create(regex_element_t *inner) {
    regex_element_t *elem = malloc(sizeof(regex_element_t));
    if (!elem) return NULL;
    
    elem->type = REGEX_QUESTION;
    elem->data = NULL;
    elem->left = inner;
    elem->right = NULL;
    elem->apply = question_apply;
    elem->destroy = question_destroy;
    
    return elem;
}

static bitmask_t *question_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text) {
    if (!self || !input || !text) return NULL;
    
    if (debug) {
        printf("Question:\n");
    }
    
    // Copy input (zero matches)
    bitmask_t *result = bitmask_copy(input);
    if (!result) return NULL;
    
    // Apply inner element (one match)
    bitmask_t *one_match = self->left->apply(self->left, input, text, debug, opt_text);
    if (one_match) {
        bitmask_or(result, one_match);
        bitmask_destroy(one_match);
    }
    
    return result;
}

static void question_destroy(regex_element_t *self) {
    if (self) {
        if (self->left) self->left->destroy(self->left);
        free(self);
    }
}

// Any character element
regex_element_t *any_char_create(void) {
    regex_element_t *elem = malloc(sizeof(regex_element_t));
    if (!elem) return NULL;
    
    elem->type = REGEX_ANY_CHAR;
    elem->data = NULL;
    elem->left = NULL;
    elem->right = NULL;
    elem->apply = any_char_apply;
    elem->destroy = any_char_destroy;
    
    return elem;
}

static bitmask_t *any_char_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text) {
    if (!self || !input || !text) return NULL;
    
    size_t text_len = strlen(text);
    bitmask_t *output = bitmask_create(input->size);
    if (!output) return NULL;
    
    if (debug) {
        printf("Any Char (.):\n");
    }
    
    // Check each position where input mask is set
    size_t count;
    int *positions = bitmask_get_set_positions(input, &count);
    if (positions) {
        for (size_t i = 0; i < count; i++) {
            int pos = positions[i];
            if (pos < (int)text_len && text[pos] != '\n') {
                bitmask_set(output, pos + 1);
            }
        }
        free(positions);
    }
    
    return output;
}

static void any_char_destroy(regex_element_t *self) {
    if (self) {
        free(self);
    }
}

// Character class element (simplified)
regex_element_t *char_class_create(const char *pattern) {
    regex_element_t *elem = malloc(sizeof(regex_element_t));
    if (!elem) return NULL;
    
    char_class_data_t *data = malloc(sizeof(char_class_data_t));
    if (!data) {
        free(elem);
        return NULL;
    }
    
    data->pattern = strdup(pattern);
    data->negated = (pattern[0] == '^');
    
    elem->type = REGEX_CHAR_CLASS;
    elem->data = data;
    elem->left = NULL;
    elem->right = NULL;
    elem->apply = char_class_apply;
    elem->destroy = char_class_destroy;
    
    return elem;
}

static bool char_matches_class(char c, const char *pattern) {
    // Simplified character class matching
    // This is a basic implementation - full implementation would handle ranges, etc.
    
    if (strcmp(pattern, "d") == 0) {
        return isdigit(c);
    } else if (strcmp(pattern, "D") == 0) {
        return !isdigit(c);
    } else if (strcmp(pattern, "s") == 0) {
        return isspace(c);
    } else if (strcmp(pattern, "S") == 0) {
        return !isspace(c);
    } else if (strcmp(pattern, "w") == 0) {
        return isalnum(c) || c == '_';
    } else if (strcmp(pattern, "W") == 0) {
        return !(isalnum(c) || c == '_');
    }
    
    // For other patterns, just check if character is in the pattern
    return strchr(pattern, c) != NULL;
}

static bitmask_t *char_class_apply(regex_element_t *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text) {
    if (!self || !input || !text) return NULL;
    
    char_class_data_t *data = (char_class_data_t *)self->data;
    size_t text_len = strlen(text);
    bitmask_t *output = bitmask_create(input->size);
    if (!output) return NULL;
    
    if (debug) {
        printf("Character Class [%s]:\n", data->pattern);
    }
    
    // Check each position where input mask is set
    size_t count;
    int *positions = bitmask_get_set_positions(input, &count);
    if (positions) {
        for (size_t i = 0; i < count; i++) {
            int pos = positions[i];
            if (pos < (int)text_len) {
                bool matches = char_matches_class(text[pos], data->pattern);
                if (data->negated) matches = !matches;
                
                if (matches) {
                    bitmask_set(output, pos + 1);
                }
            }
        }
        free(positions);
    }
    
    return output;
}

static void char_class_destroy(regex_element_t *self) {
    if (self) {
        char_class_data_t *data = (char_class_data_t *)self->data;
        if (data) {
            free(data->pattern);
            free(data);
        }
        free(self);
    }
}
