#ifndef FLOWREGEX_H
#define FLOWREGEX_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include "optimized_text.h"

// Maximum text length supported
#define FLOWREGEX_MAX_TEXT_LENGTH 100000

// Error codes
typedef enum {
    FLOWREGEX_OK = 0,
    FLOWREGEX_ERROR_PARSE = -1,
    FLOWREGEX_ERROR_MEMORY = -2,
    FLOWREGEX_ERROR_TEXT_TOO_LONG = -3,
    FLOWREGEX_ERROR_INVALID_PATTERN = -4
} flowregex_error_t;

// Forward declarations
struct flowregex;
struct bitmask;
struct regex_element;

// BitMask structure for position management
typedef struct bitmask {
    uint64_t *bits;
    size_t size;
    size_t capacity;
} bitmask_t;

// Match result structure
typedef struct {
    int *positions;
    size_t count;
    size_t capacity;
} match_result_t;

// Regex element types
typedef enum {
    REGEX_LITERAL,
    REGEX_CONCAT,
    REGEX_ALTERNATION,
    REGEX_KLEENE_STAR,
    REGEX_PLUS,
    REGEX_QUESTION,
    REGEX_ANY_CHAR,
    REGEX_CHAR_CLASS
} regex_element_type_t;

// Base regex element structure
typedef struct regex_element {
    regex_element_type_t type;
    void *data;
    struct regex_element *left;
    struct regex_element *right;
    bitmask_t *(*apply)(struct regex_element *self, bitmask_t *input, const char *text, bool debug, optimized_text_t *opt_text);
    void (*destroy)(struct regex_element *self);
} regex_element_t;

// Literal element data
typedef struct {
    char character;
} literal_data_t;

// Character class data
typedef struct {
    char *pattern;
    bool negated;
} char_class_data_t;

// Main FlowRegex structure
typedef struct flowregex {
    char *pattern;
    regex_element_t *root;
} flowregex_t;

// BitMask functions
bitmask_t *bitmask_create(size_t size);
void bitmask_destroy(bitmask_t *mask);
void bitmask_set(bitmask_t *mask, size_t pos);
void bitmask_clear(bitmask_t *mask, size_t pos);
bool bitmask_get(const bitmask_t *mask, size_t pos);
void bitmask_or(bitmask_t *dest, const bitmask_t *src);
void bitmask_and(bitmask_t *dest, const bitmask_t *src);
bitmask_t *bitmask_copy(const bitmask_t *src);
void bitmask_clear_all(bitmask_t *mask);
int *bitmask_get_set_positions(const bitmask_t *mask, size_t *count);
#ifdef DEBUG
void bitmask_print(const bitmask_t *mask, const char *label);
#endif

// Match result functions
match_result_t *match_result_create(void);
void match_result_destroy(match_result_t *result);
void match_result_add(match_result_t *result, int position);

// Regex element constructors
regex_element_t *literal_create(char c);
regex_element_t *concat_create(regex_element_t *left, regex_element_t *right);
regex_element_t *alternation_create(regex_element_t *left, regex_element_t *right);
regex_element_t *kleene_star_create(regex_element_t *inner);
regex_element_t *plus_create(regex_element_t *inner);
regex_element_t *question_create(regex_element_t *inner);
regex_element_t *any_char_create(void);
regex_element_t *char_class_create(const char *pattern);

// Parser functions
regex_element_t *parse_regex(const char *pattern, flowregex_error_t *error);

// Main FlowRegex API
flowregex_t *flowregex_create(const char *pattern, flowregex_error_t *error);
void flowregex_destroy(flowregex_t *regex);
match_result_t *flowregex_match(flowregex_t *regex, const char *text, bool debug);

// Utility functions
void flowregex_print_error(flowregex_error_t error);
const char *flowregex_error_string(flowregex_error_t error);

#endif // FLOWREGEX_H
