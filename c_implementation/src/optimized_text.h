#ifndef OPTIMIZED_TEXT_H
#define OPTIMIZED_TEXT_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

// Forward declaration (bitmask_t is defined in flowregex.h)
struct bitmask;

// MatchMask最適化のための構造体
typedef struct {
    char *text;
    size_t text_length;
    struct bitmask **match_masks;  // 各文字のMatchMask
    char *precomputed_chars;  // 事前計算された文字の配列
    size_t precomputed_count; // 事前計算された文字数
} optimized_text_t;

// オフセット付きビットマスク（シフト演算を論理的に管理）
typedef struct {
    struct bitmask *bits;
    int offset;  // 論理的なオフセット位置
} offset_bitmask_t;

// OptimizedText関数
optimized_text_t *optimized_text_create(const char *text, const char *alphabets);
void optimized_text_destroy(optimized_text_t *opt_text);
struct bitmask *optimized_text_get_match_mask(optimized_text_t *opt_text, char c);

// オフセット付きビットマスク関数
offset_bitmask_t *offset_bitmask_create(size_t size, int offset);
void offset_bitmask_destroy(offset_bitmask_t *mask);
offset_bitmask_t *offset_bitmask_copy(const offset_bitmask_t *src);
void offset_bitmask_and_with_offset(offset_bitmask_t *dest, const struct bitmask *match_mask);
void offset_bitmask_or(offset_bitmask_t *dest, const offset_bitmask_t *src);
bool offset_bitmask_has_bits(const offset_bitmask_t *mask);

// 最適化されたリテラル処理
offset_bitmask_t *literal_apply_optimized(char c, offset_bitmask_t *input, optimized_text_t *opt_text);

#endif // OPTIMIZED_TEXT_H
