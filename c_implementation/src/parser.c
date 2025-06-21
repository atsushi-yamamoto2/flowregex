#include "flowregex.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>

typedef struct {
    const char *pattern;
    size_t pos;
    size_t length;
    flowregex_error_t *error;
} parser_state_t;

// Forward declarations
static regex_element_t *parse_expression(parser_state_t *state);
static regex_element_t *parse_term(parser_state_t *state);
static regex_element_t *parse_factor(parser_state_t *state);
static regex_element_t *parse_atom(parser_state_t *state);

static char current_char(parser_state_t *state) {
    if (state->pos >= state->length) return '\0';
    return state->pattern[state->pos];
}

static void advance(parser_state_t *state) {
    if (state->pos < state->length) {
        state->pos++;
    }
}

static bool at_end(parser_state_t *state) {
    return state->pos >= state->length;
}

static bool consume(parser_state_t *state, char expected) {
    if (current_char(state) == expected) {
        advance(state);
        return true;
    }
    return false;
}

// Expression := Term ('|' Term)*
static regex_element_t *parse_expression(parser_state_t *state) {
    regex_element_t *left = parse_term(state);
    if (!left) return NULL;
    
    while (current_char(state) == '|') {
        advance(state); // consume '|'
        regex_element_t *right = parse_term(state);
        if (!right) {
            left->destroy(left);
            return NULL;
        }
        left = alternation_create(left, right);
        if (!left) {
            right->destroy(right);
            return NULL;
        }
    }
    
    return left;
}

// Term := Factor*
static regex_element_t *parse_term(parser_state_t *state) {
    regex_element_t *result = NULL;
    
    while (!at_end(state) && current_char(state) != '|' && current_char(state) != ')') {
        regex_element_t *factor = parse_factor(state);
        if (!factor) {
            if (result) result->destroy(result);
            return NULL;
        }
        
        if (result) {
            result = concat_create(result, factor);
            if (!result) {
                factor->destroy(factor);
                return NULL;
            }
        } else {
            result = factor;
        }
    }
    
    return result;
}

// Factor := Atom ('*' | '+' | '?')?
static regex_element_t *parse_factor(parser_state_t *state) {
    regex_element_t *atom = parse_atom(state);
    if (!atom) return NULL;
    
    char c = current_char(state);
    switch (c) {
        case '*':
            advance(state);
            return kleene_star_create(atom);
        case '+':
            advance(state);
            return plus_create(atom);
        case '?':
            advance(state);
            return question_create(atom);
        default:
            return atom;
    }
}

// Atom := CHAR | '(' Expression ')' | '.' | '\' EscapeChar
static regex_element_t *parse_atom(parser_state_t *state) {
    char c = current_char(state);
    
    switch (c) {
        case '\0':
            *(state->error) = FLOWREGEX_ERROR_PARSE;
            return NULL;
            
        case '(':
            advance(state); // consume '('
            {
                regex_element_t *expr = parse_expression(state);
                if (!expr) return NULL;
                
                if (!consume(state, ')')) {
                    expr->destroy(expr);
                    *(state->error) = FLOWREGEX_ERROR_PARSE;
                    return NULL;
                }
                return expr;
            }
            
        case '.':
            advance(state);
            return any_char_create();
            
        case '\\':
            advance(state); // consume '\'
            {
                char escape_char = current_char(state);
                if (escape_char == '\0') {
                    *(state->error) = FLOWREGEX_ERROR_PARSE;
                    return NULL;
                }
                advance(state);
                
                // Handle character classes
                switch (escape_char) {
                    case 'd':
                        return char_class_create("d");
                    case 'D':
                        return char_class_create("D");
                    case 's':
                        return char_class_create("s");
                    case 'S':
                        return char_class_create("S");
                    case 'w':
                        return char_class_create("w");
                    case 'W':
                        return char_class_create("W");
                    case 'n':
                        return literal_create('\n');
                    case 't':
                        return literal_create('\t');
                    case 'r':
                        return literal_create('\r');
                    case '\\':
                        return literal_create('\\');
                    case '.':
                        return literal_create('.');
                    default:
                        return literal_create(escape_char);
                }
            }
            
        case '|':
        case ')':
        case '*':
        case '+':
        case '?':
            *(state->error) = FLOWREGEX_ERROR_PARSE;
            return NULL;
            
        default:
            advance(state);
            return literal_create(c);
    }
}

regex_element_t *parse_regex(const char *pattern, flowregex_error_t *error) {
    if (!pattern || !error) {
        if (error) *error = FLOWREGEX_ERROR_INVALID_PATTERN;
        return NULL;
    }
    
    *error = FLOWREGEX_OK;
    
    parser_state_t state = {
        .pattern = pattern,
        .pos = 0,
        .length = strlen(pattern),
        .error = error
    };
    
    if (state.length == 0) {
        *error = FLOWREGEX_ERROR_INVALID_PATTERN;
        return NULL;
    }
    
    regex_element_t *result = parse_expression(&state);
    
    if (result && !at_end(&state)) {
        result->destroy(result);
        *error = FLOWREGEX_ERROR_PARSE;
        return NULL;
    }
    
    return result;
}
