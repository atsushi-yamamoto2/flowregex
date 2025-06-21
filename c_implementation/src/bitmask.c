#include "flowregex.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// Number of bits per uint64_t
#define BITS_PER_WORD 64

// Calculate number of words needed for given bit count
static size_t words_needed(size_t bits) {
    return (bits + BITS_PER_WORD - 1) / BITS_PER_WORD;
}

bitmask_t *bitmask_create(size_t size) {
    bitmask_t *mask = malloc(sizeof(bitmask_t));
    if (!mask) return NULL;
    
    mask->size = size;
    mask->capacity = words_needed(size);
    mask->bits = calloc(mask->capacity, sizeof(uint64_t));
    
    if (!mask->bits) {
        free(mask);
        return NULL;
    }
    
    return mask;
}

void bitmask_destroy(bitmask_t *mask) {
    if (mask) {
        free(mask->bits);
        free(mask);
    }
}

void bitmask_set(bitmask_t *mask, size_t pos) {
    if (!mask || pos >= mask->size) return;
    
    size_t word_idx = pos / BITS_PER_WORD;
    size_t bit_idx = pos % BITS_PER_WORD;
    
    mask->bits[word_idx] |= (1ULL << bit_idx);
}

void bitmask_clear(bitmask_t *mask, size_t pos) {
    if (!mask || pos >= mask->size) return;
    
    size_t word_idx = pos / BITS_PER_WORD;
    size_t bit_idx = pos % BITS_PER_WORD;
    
    mask->bits[word_idx] &= ~(1ULL << bit_idx);
}

bool bitmask_get(const bitmask_t *mask, size_t pos) {
    if (!mask || pos >= mask->size) return false;
    
    size_t word_idx = pos / BITS_PER_WORD;
    size_t bit_idx = pos % BITS_PER_WORD;
    
    return (mask->bits[word_idx] & (1ULL << bit_idx)) != 0;
}

void bitmask_or(bitmask_t *dest, const bitmask_t *src) {
    if (!dest || !src) return;
    
    size_t min_capacity = dest->capacity < src->capacity ? dest->capacity : src->capacity;
    
    for (size_t i = 0; i < min_capacity; i++) {
        dest->bits[i] |= src->bits[i];
    }
}

void bitmask_and(bitmask_t *dest, const bitmask_t *src) {
    if (!dest || !src) return;
    
    size_t min_capacity = dest->capacity < src->capacity ? dest->capacity : src->capacity;
    
    for (size_t i = 0; i < min_capacity; i++) {
        dest->bits[i] &= src->bits[i];
    }
    
    // Clear remaining bits in dest if it's larger
    for (size_t i = min_capacity; i < dest->capacity; i++) {
        dest->bits[i] = 0;
    }
}

bitmask_t *bitmask_copy(const bitmask_t *src) {
    if (!src) return NULL;
    
    bitmask_t *copy = bitmask_create(src->size);
    if (!copy) return NULL;
    
    memcpy(copy->bits, src->bits, src->capacity * sizeof(uint64_t));
    
    return copy;
}

void bitmask_clear_all(bitmask_t *mask) {
    if (!mask) return;
    
    memset(mask->bits, 0, mask->capacity * sizeof(uint64_t));
}

int *bitmask_get_set_positions(const bitmask_t *mask, size_t *count) {
    if (!mask || !count) return NULL;
    
    // First pass: count set bits
    *count = 0;
    for (size_t i = 0; i < mask->size; i++) {
        if (bitmask_get(mask, i)) {
            (*count)++;
        }
    }
    
    if (*count == 0) return NULL;
    
    // Second pass: collect positions
    int *positions = malloc(*count * sizeof(int));
    if (!positions) {
        *count = 0;
        return NULL;
    }
    
    size_t idx = 0;
    for (size_t i = 0; i < mask->size; i++) {
        if (bitmask_get(mask, i)) {
            positions[idx++] = (int)i;
        }
    }
    
    return positions;
}

#ifdef DEBUG
void bitmask_print(const bitmask_t *mask, const char *label) {
    if (!mask) {
        printf("%s: NULL\n", label ? label : "BitMask");
        return;
    }
    
    printf("%s: [", label ? label : "BitMask");
    bool first = true;
    for (size_t i = 0; i < mask->size; i++) {
        if (bitmask_get(mask, i)) {
            if (!first) printf(", ");
            printf("%zu", i);
            first = false;
        }
    }
    printf("]\n");
}
#endif
