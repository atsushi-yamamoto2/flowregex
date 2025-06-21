#include "src/flowregex.h"
#include <stdio.h>
#include <string.h>
#include <time.h>

int main() {
    printf("FlowRegex 最適化テスト\n");
    printf("=====================\n\n");
    
    const char *text = "ATGCATGCATGC";
    const char *pattern = "ATG";
    
    // OptimizedTextを作成
    optimized_text_t *opt_text = optimized_text_create(text, "ATGC");
    if (!opt_text) {
        printf("OptimizedText作成失敗\n");
        return 1;
    }
    
    printf("テキスト: %s\n", text);
    printf("パターン: %s\n", pattern);
    printf("OptimizedText作成成功\n");
    
    // 各文字のMatchMaskを確認
    for (char c = 'A'; c <= 'T'; c++) {
        if (c == 'B' || c == 'E' || (c > 'G' && c < 'T')) continue;
        
        struct bitmask *mask = optimized_text_get_match_mask(opt_text, c);
        if (mask) {
            printf("文字 '%c' のMatchMask: ", c);
            for (size_t i = 0; i < strlen(text); i++) {
                printf("%d", bitmask_get(mask, i) ? 1 : 0);
            }
            printf("\n");
        }
    }
    
    // FlowRegex処理
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create(pattern, &error);
    if (!regex) {
        printf("FlowRegex作成失敗: %s\n", flowregex_error_string(error));
        optimized_text_destroy(opt_text);
        return 1;
    }
    
    // 従来処理
    clock_t start = clock();
    match_result_t *result1 = flowregex_match(regex, text, false);
    clock_t end = clock();
    double time1 = ((double)(end - start)) / CLOCKS_PER_SEC * 1000.0;
    
    // 最適化処理（手動でapply関数を呼び出し）
    start = clock();
    bitmask_t *initial_mask = bitmask_create(strlen(text) + 1);
    for (size_t i = 0; i <= strlen(text); i++) {
        bitmask_set(initial_mask, i);
    }
    bitmask_t *result_mask = regex->root->apply(regex->root, initial_mask, text, false, opt_text);
    end = clock();
    double time2 = ((double)(end - start)) / CLOCKS_PER_SEC * 1000.0;
    
    printf("\n結果:\n");
    printf("従来処理: %.3f ms\n", time1);
    printf("最適化処理: %.3f ms\n", time2);
    printf("高速化倍率: %.1fx\n", time1 / time2);
    
    if (result1) {
        printf("マッチ数: %zu\n", result1->count);
        match_result_destroy(result1);
    }
    
    bitmask_destroy(initial_mask);
    bitmask_destroy(result_mask);
    flowregex_destroy(regex);
    optimized_text_destroy(opt_text);
    
    return 0;
}
