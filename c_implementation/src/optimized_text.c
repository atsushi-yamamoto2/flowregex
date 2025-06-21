#include "optimized_text.h"
#include "flowregex.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// OptimizedText実装

optimized_text_t *optimized_text_create(const char *text, const char *alphabets) {
    if (!text || !alphabets) return NULL;
    
    optimized_text_t *opt_text = malloc(sizeof(optimized_text_t));
    if (!opt_text) return NULL;
    
    // テキストをコピー
    opt_text->text_length = strlen(text);
    opt_text->text = strdup(text);
    if (!opt_text->text) {
        free(opt_text);
        return NULL;
    }
    
    // 事前計算する文字を設定
    opt_text->precomputed_count = strlen(alphabets);
    opt_text->precomputed_chars = strdup(alphabets);
    if (!opt_text->precomputed_chars) {
        free(opt_text->text);
        free(opt_text);
        return NULL;
    }
    
    // MatchMask配列を初期化
    opt_text->match_masks = calloc(256, sizeof(struct bitmask*));
    if (!opt_text->match_masks) {
        free(opt_text->precomputed_chars);
        free(opt_text->text);
        free(opt_text);
        return NULL;
    }
    
    // 各文字のMatchMaskを事前計算
    for (size_t i = 0; i < opt_text->precomputed_count; i++) {
        char c = alphabets[i];
        unsigned char idx = (unsigned char)c;
        
        opt_text->match_masks[idx] = bitmask_create(opt_text->text_length + 1);
        if (!opt_text->match_masks[idx]) {
            optimized_text_destroy(opt_text);
            return NULL;
        }
        
        // テキスト中の文字cの位置をマーク
        for (size_t pos = 0; pos < opt_text->text_length; pos++) {
            if (text[pos] == c) {
                bitmask_set(opt_text->match_masks[idx], pos);
            }
        }
    }
    
    return opt_text;
}

void optimized_text_destroy(optimized_text_t *opt_text) {
    if (!opt_text) return;
    
    if (opt_text->match_masks) {
        for (int i = 0; i < 256; i++) {
            if (opt_text->match_masks[i]) {
                bitmask_destroy(opt_text->match_masks[i]);
            }
        }
        free(opt_text->match_masks);
    }
    
    free(opt_text->precomputed_chars);
    free(opt_text->text);
    free(opt_text);
}

struct bitmask *optimized_text_get_match_mask(optimized_text_t *opt_text, char c) {
    if (!opt_text) return NULL;
    
    unsigned char idx = (unsigned char)c;
    return opt_text->match_masks[idx];
}

// オフセット付きビットマスク実装

offset_bitmask_t *offset_bitmask_create(size_t size, int offset) {
    offset_bitmask_t *mask = malloc(sizeof(offset_bitmask_t));
    if (!mask) return NULL;
    
    mask->bits = bitmask_create(size);
    if (!mask->bits) {
        free(mask);
        return NULL;
    }
    
    mask->offset = offset;
    return mask;
}

void offset_bitmask_destroy(offset_bitmask_t *mask) {
    if (mask) {
        bitmask_destroy(mask->bits);
        free(mask);
    }
}

offset_bitmask_t *offset_bitmask_copy(const offset_bitmask_t *src) {
    if (!src) return NULL;
    
    offset_bitmask_t *copy = malloc(sizeof(offset_bitmask_t));
    if (!copy) return NULL;
    
    copy->bits = bitmask_copy(src->bits);
    if (!copy->bits) {
        free(copy);
        return NULL;
    }
    
    copy->offset = src->offset;
    return copy;
}

void offset_bitmask_and_with_offset(offset_bitmask_t *dest, const struct bitmask *match_mask) {
    if (!dest || !match_mask || !dest->bits) return;
    
    // オフセットを考慮したAND演算
    // dest->offset分だけずらしてmatch_maskとAND演算
    struct bitmask *temp = bitmask_create(dest->bits->size);
    if (!temp) return;
    
    // match_maskをoffset分ずらしてtempにコピー
    size_t count;
    int *positions = bitmask_get_set_positions(match_mask, &count);
    if (positions) {
        for (size_t i = 0; i < count; i++) {
            int shifted_pos = positions[i] + dest->offset;
            if (shifted_pos >= 0 && shifted_pos < (int)temp->size) {
                bitmask_set(temp, shifted_pos);
            }
        }
        free(positions);
    }
    
    // dest->bitsとtempのAND演算
    bitmask_and(dest->bits, temp);
    bitmask_destroy(temp);
    
    // オフセットを1増加（次の文字位置へ）
    dest->offset++;
}

void offset_bitmask_or(offset_bitmask_t *dest, const offset_bitmask_t *src) {
    if (!dest || !src || !dest->bits || !src->bits) return;
    
    // 同じオフセットの場合は単純なOR
    if (dest->offset == src->offset) {
        bitmask_or(dest->bits, src->bits);
        return;
    }
    
    // オフセットが異なる場合は調整が必要
    // 簡単のため、ここでは同じオフセットのみ対応
    if (dest->offset == src->offset) {
        bitmask_or(dest->bits, src->bits);
    }
}

bool offset_bitmask_has_bits(const offset_bitmask_t *mask) {
    if (!mask || !mask->bits) return false;
    
    // ビットマスクに設定されたビットがあるかチェック
    for (size_t i = 0; i < mask->bits->size; i++) {
        if (bitmask_get(mask->bits, i)) {
            return true;
        }
    }
    return false;
}

// 最適化されたリテラル処理

offset_bitmask_t *literal_apply_optimized(char c, offset_bitmask_t *input, optimized_text_t *opt_text) {
    if (!input || !opt_text) return NULL;
    
    // MatchMaskを取得
    struct bitmask *match_mask = optimized_text_get_match_mask(opt_text, c);
    if (!match_mask) {
        // 事前計算されていない文字の場合は従来処理
        return NULL;
    }
    
    // 結果用のオフセットビットマスクを作成
    offset_bitmask_t *result = offset_bitmask_copy(input);
    if (!result) return NULL;
    
    // 最適化されたAND演算（シフトなし）
    offset_bitmask_and_with_offset(result, match_mask);
    
    return result;
}
