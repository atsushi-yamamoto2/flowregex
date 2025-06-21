#include "src/optimized_text.h"
#include "src/flowregex.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <regex.h>

// DNA配列生成（測定ごとに異なる配列）
char* generate_dna_sequence(int length, int seed) {
    char *sequence = malloc(length + 1);
    if (!sequence) return NULL;
    
    const char bases[] = "ATGC";
    srand(seed); // 測定ごとに異なるシード
    
    for (int i = 0; i < length; i++) {
        sequence[i] = bases[rand() % 4];
    }
    sequence[length] = '\0';
    
    return sequence;
}

// FlowRegex従来処理のベンチマーク
double benchmark_flowregex_traditional(const char* text, const char* pattern, int iterations) {
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create(pattern, &error);
    if (!regex) return -1.0;
    
    clock_t start = clock();
    
    for (int i = 0; i < iterations; i++) {
        match_result_t *result = flowregex_match(regex, text, false);
        if (result) {
            match_result_destroy(result);
        }
    }
    
    clock_t end = clock();
    flowregex_destroy(regex);
    
    return ((double)(end - start)) / CLOCKS_PER_SEC * 1000.0;
}

// MatchMask最適化処理のベンチマーク
double benchmark_matchmask_optimized(const char* text, const char* pattern, int iterations) {
    // OptimizedTextを作成
    optimized_text_t *opt_text = optimized_text_create(text, "ATGC");
    if (!opt_text) return -1.0;
    
    // FlowRegexパターンを解析
    flowregex_error_t error;
    flowregex_t *regex = flowregex_create(pattern, &error);
    if (!regex) {
        optimized_text_destroy(opt_text);
        return -1.0;
    }
    
    // 事前に初期ビットマスクを作成（再利用）
    size_t text_len = strlen(text);
    bitmask_t *initial_mask = bitmask_create(text_len + 1);
    if (!initial_mask) {
        flowregex_destroy(regex);
        optimized_text_destroy(opt_text);
        return -1.0;
    }
    
    // 全ての位置から開始可能に設定
    for (size_t pos = 0; pos <= text_len; pos++) {
        bitmask_set(initial_mask, pos);
    }
    
    clock_t start = clock();
    
    for (int i = 0; i < iterations; i++) {
        // 正規表現要素を適用（OptimizedTextを渡す）
        bitmask_t *result_mask = regex->root->apply(regex->root, initial_mask, text, false, opt_text);
        
        if (result_mask) {
            bitmask_destroy(result_mask);
        }
    }
    
    clock_t end = clock();
    
    bitmask_destroy(initial_mask);
    flowregex_destroy(regex);
    optimized_text_destroy(opt_text);
    
    return ((double)(end - start)) / CLOCKS_PER_SEC * 1000.0;
}

// POSIX正規表現ベンチマーク
double benchmark_posix_regex(const char* text, const char* pattern, int iterations) {
    regex_t regex;
    int ret = regcomp(&regex, pattern, REG_EXTENDED);
    if (ret != 0) return -1.0;
    
    clock_t start = clock();
    
    for (int i = 0; i < iterations; i++) {
        regmatch_t match;
        regexec(&regex, text, 1, &match, 0);
    }
    
    clock_t end = clock();
    regfree(&regex);
    
    return ((double)(end - start)) / CLOCKS_PER_SEC * 1000.0;
}

// テーブル形式での結果表示
void run_fair_comparison_benchmark() {
    printf("FlowRegex 性能比較ベンチマーク\n");
    printf("==============================\n\n");
    
    const int text_lengths[] = {1000, 5000, 10000};
    const char* patterns[] = {"ATG", "A.G", "AT*", "A+T", "G?C", "(A|T)GC"};
    const int iterations = 5000; // 適度な測定精度
    
    printf("測定条件:\n");
    printf("- 反復回数: %d回\n", iterations);
    printf("- DNA配列: ランダム生成（ATGC）\n");
    printf("- すべて実際のマッチング処理を測定\n\n");
    
    // ヘッダー
    printf("%-12s %-8s %-15s %-15s %-15s %-12s %-12s\n",
           "テキスト長", "パターン", "FlowRegex(ms)", "MatchMask(ms)", "POSIX(ms)", 
           "MM高速化", "対POSIX");
    printf("%-12s %-8s %-15s %-15s %-15s %-12s %-12s\n",
           "----------", "--------", "-------------", "-------------", "---------", 
           "--------", "--------");
    
    for (size_t len_idx = 0; len_idx < sizeof(text_lengths) / sizeof(text_lengths[0]); len_idx++) {
        int text_len = text_lengths[len_idx];
        char *dna_text = generate_dna_sequence(text_len, 42 + len_idx);
        if (!dna_text) continue;
        
        for (size_t pat_idx = 0; pat_idx < sizeof(patterns) / sizeof(patterns[0]); pat_idx++) {
            const char *pattern = patterns[pat_idx];
            
            // ウォームアップ実行（結果は破棄）
            benchmark_flowregex_traditional(dna_text, pattern, 10);
            benchmark_matchmask_optimized(dna_text, pattern, 10);
            benchmark_posix_regex(dna_text, pattern, 10);
            
            // 実際の測定（3回実行して平均を取る）
            double flowregex_times[3], matchmask_times[3], posix_times[3];
            
            for (int run = 0; run < 3; run++) {
                flowregex_times[run] = benchmark_flowregex_traditional(dna_text, pattern, iterations);
                matchmask_times[run] = benchmark_matchmask_optimized(dna_text, pattern, iterations);
                posix_times[run] = benchmark_posix_regex(dna_text, pattern, iterations);
            }
            
            // 平均値を計算
            double flowregex_time = (flowregex_times[0] + flowregex_times[1] + flowregex_times[2]) / 3.0;
            double matchmask_time = (matchmask_times[0] + matchmask_times[1] + matchmask_times[2]) / 3.0;
            double posix_time = (posix_times[0] + posix_times[1] + posix_times[2]) / 3.0;
            
            // 高速化倍率の計算
            double mm_speedup = (flowregex_time > 0 && matchmask_time > 0) ? 
                               flowregex_time / matchmask_time : 0.0;
            double posix_speedup = (posix_time > 0 && matchmask_time > 0) ? 
                                  posix_time / matchmask_time : 0.0;
            
            // 結果表示
            printf("%-12d %-8s %-15.2f %-15.2f %-15.2f %-12.1fx %-12.1fx\n",
                   text_len, pattern, 
                   flowregex_time >= 0 ? flowregex_time : 0.0,
                   matchmask_time >= 0 ? matchmask_time : 0.0,
                   posix_time >= 0 ? posix_time : 0.0,
                   mm_speedup, posix_speedup);
        }
        
        free(dna_text);
    }
    
    printf("\n");
}

// 事前計算コストの分析（テーブル形式）
void analyze_preprocessing_cost() {
    printf("=== 事前計算コスト分析 ===\n");
    
    const int text_lengths[] = {1000, 5000, 10000, 50000};
    
    printf("%-12s %-15s %-15s %-15s\n",
           "テキスト長", "事前計算(ms)", "メモリ(KB)", "文字単価(B)");
    printf("%-12s %-15s %-15s %-15s\n",
           "----------", "-------------", "-----------", "-----------");
    
    for (size_t i = 0; i < sizeof(text_lengths) / sizeof(text_lengths[0]); i++) {
        int text_len = text_lengths[i];
        char *dna_text = generate_dna_sequence(text_len, 100 + i);
        if (!dna_text) continue;
        
        // OptimizedText作成時間
        clock_t start = clock();
        optimized_text_t *opt_text = optimized_text_create(dna_text, "ATGC");
        clock_t end = clock();
        
        if (opt_text) {
            double creation_time = ((double)(end - start)) / CLOCKS_PER_SEC * 1000.0;
            
            // メモリ使用量推定
            size_t memory_usage = sizeof(optimized_text_t) +
                                 text_len + 1 +  // text
                                 5 +             // "ATGC" + null
                                 256 * sizeof(bitmask_t*) + // match_masks array
                                 4 * (sizeof(bitmask_t) + (text_len + 1 + 63) / 64 * sizeof(uint64_t));
            
            printf("%-12d %-15.2f %-15.2f %-15.2f\n",
                   text_len, creation_time, memory_usage / 1024.0, 
                   (double)memory_usage / text_len);
            
            optimized_text_destroy(opt_text);
        } else {
            printf("%-12d %-15s %-15s %-15s\n", text_len, "エラー", "エラー", "エラー");
        }
        
        free(dna_text);
    }
    
    printf("\n");
}

int main() {
    printf("FlowRegex 公平な性能比較ベンチマーク\n");
    printf("=====================================\n\n");
    
    run_fair_comparison_benchmark();
    analyze_preprocessing_cost();
    
    printf("ベンチマーク完了\n");
    printf("\n注意事項:\n");
    printf("- MM高速化: MatchMaskがFlowRegex従来処理より何倍高速か\n");
    printf("- 対POSIX: MatchMaskがPOSIX正規表現より何倍高速か\n");
    printf("- 事前計算コストは同一テキストへの複数回マッチングで償却される\n");
    
    return 0;
}
