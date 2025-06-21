#include "src/optimized_text.h"
#include "src/flowregex.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <regex.h>

// DNA配列生成
char* generate_dna_sequence(int length, int seed) {
    char *sequence = malloc(length + 1);
    if (!sequence) return NULL;
    
    const char bases[] = "ATGC";
    srand(seed);
    
    for (int i = 0; i < length; i++) {
        sequence[i] = bases[rand() % 4];
    }
    sequence[length] = '\0';
    
    return sequence;
}

// マッチ結果の詳細分析
void analyze_match_results() {
    printf("=== マッチ結果の詳細分析 ===\n\n");
    
    const int text_lengths[] = {1000, 5000, 10000};
    const char* patterns[] = {"ATG", "TATA", "GAATTC"};
    
    printf("%-12s %-8s %-12s %-12s %-12s %-15s %-15s\n",
           "テキスト長", "パターン", "FlowRegex", "MatchMask", "POSIX", "FlowRegex(ms)", "MatchMask(ms)");
    printf("%-12s %-8s %-12s %-12s %-12s %-15s %-15s\n",
           "----------", "--------", "----------", "----------", "----------", "-------------", "-------------");
    
    for (size_t len_idx = 0; len_idx < 3; len_idx++) {
        int text_len = text_lengths[len_idx];
        char *dna_text = generate_dna_sequence(text_len, 42 + len_idx);
        if (!dna_text) continue;
        
        for (size_t pat_idx = 0; pat_idx < 3; pat_idx++) {
            const char *pattern = patterns[pat_idx];
            
            // FlowRegex従来処理
            flowregex_error_t error;
            flowregex_t *regex = flowregex_create(pattern, &error);
            int flowregex_matches = 0;
            double flowregex_time = 0.0;
            if (regex) {
                clock_t start = clock();
                match_result_t *result = flowregex_match(regex, dna_text, false);
                clock_t end = clock();
                flowregex_time = ((double)(end - start)) / CLOCKS_PER_SEC * 1000.0;
                if (result) {
                    flowregex_matches = result->count;
                    match_result_destroy(result);
                }
                flowregex_destroy(regex);
            }
            
            // MatchMask最適化処理（全マッチを検索）
            optimized_text_t *opt_text = optimized_text_create(dna_text, "ATGC");
            int matchmask_matches = 0;
            double matchmask_time = 0.0;
            if (opt_text) {
                clock_t start = clock();
                
                size_t text_len_size = strlen(dna_text);
                size_t pattern_len = strlen(pattern);
                
                bitmask_t *first_mask = optimized_text_get_match_mask(opt_text, pattern[0]);
                if (first_mask) {
                    for (size_t pos = 0; pos <= text_len_size - pattern_len; pos++) {
                        size_t word_idx = pos / 64;
                        size_t bit_idx = pos % 64;
                        if (word_idx < first_mask->size && (first_mask->bits[word_idx] & (1ULL << bit_idx))) {
                            bool match = true;
                            for (size_t j = 1; j < pattern_len && match; j++) {
                                if (pos + j >= text_len_size || dna_text[pos + j] != pattern[j]) {
                                    match = false;
                                }
                            }
                            if (match) matchmask_matches++;
                        }
                    }
                }
                
                clock_t end = clock();
                matchmask_time = ((double)(end - start)) / CLOCKS_PER_SEC * 1000.0;
                optimized_text_destroy(opt_text);
            }
            
            // POSIX正規表現（全マッチを検索）
            regex_t posix_regex;
            int posix_matches = 0;
            if (regcomp(&posix_regex, pattern, REG_EXTENDED) == 0) {
                const char *search_start = dna_text;
                regmatch_t match;
                while (regexec(&posix_regex, search_start, 1, &match, 0) == 0) {
                    posix_matches++;
                    search_start += match.rm_so + 1;
                    if (search_start >= dna_text + strlen(dna_text)) break;
                }
                regfree(&posix_regex);
            }
            
            printf("%-12d %-8s %-12d %-12d %-12d %-15.6f %-15.6f\n",
                   text_len, pattern, 
                   flowregex_matches, matchmask_matches, posix_matches,
                   flowregex_time, matchmask_time);
        }
        
        free(dna_text);
    }
    
    printf("\n");
}

// 早期終了の影響を調査
void analyze_early_termination() {
    printf("=== 早期終了の影響調査 ===\n\n");
    
    const int text_lengths[] = {1000, 5000, 10000};
    const char* pattern = "ATG";
    
    printf("%-12s %-15s %-15s %-15s %-15s\n",
           "テキスト長", "最初のマッチ", "全マッチ検索", "早期終了", "処理比率");
    printf("%-12s %-15s %-15s %-15s %-15s\n",
           "----------", "-------------", "-------------", "----------", "----------");
    
    for (size_t len_idx = 0; len_idx < 3; len_idx++) {
        int text_len = text_lengths[len_idx];
        char *dna_text = generate_dna_sequence(text_len, 42 + len_idx);
        if (!dna_text) continue;
        
        // 最初のマッチのみ検索
        clock_t start1 = clock();
        optimized_text_t *opt_text = optimized_text_create(dna_text, "ATGC");
        bool found_first = false;
        int first_match_pos = -1;
        if (opt_text) {
            size_t text_len_size = strlen(dna_text);
            size_t pattern_len = strlen(pattern);
            
            bitmask_t *first_mask = optimized_text_get_match_mask(opt_text, pattern[0]);
            if (first_mask) {
                for (size_t pos = 0; pos <= text_len_size - pattern_len && !found_first; pos++) {
                    size_t word_idx = pos / 64;
                    size_t bit_idx = pos % 64;
                    if (word_idx < first_mask->size && (first_mask->bits[word_idx] & (1ULL << bit_idx))) {
                        bool match = true;
                        for (size_t j = 1; j < pattern_len && match; j++) {
                            if (pos + j >= text_len_size || dna_text[pos + j] != pattern[j]) {
                                match = false;
                            }
                        }
                        if (match) {
                            found_first = true;
                            first_match_pos = pos;
                        }
                    }
                }
            }
            optimized_text_destroy(opt_text);
        }
        clock_t end1 = clock();
        double first_only_time = ((double)(end1 - start1)) / CLOCKS_PER_SEC * 1000.0;
        
        // 全マッチ検索
        clock_t start2 = clock();
        opt_text = optimized_text_create(dna_text, "ATGC");
        int total_matches = 0;
        if (opt_text) {
            size_t text_len_size = strlen(dna_text);
            size_t pattern_len = strlen(pattern);
            
            bitmask_t *first_mask = optimized_text_get_match_mask(opt_text, pattern[0]);
            if (first_mask) {
                for (size_t pos = 0; pos <= text_len_size - pattern_len; pos++) {
                    size_t word_idx = pos / 64;
                    size_t bit_idx = pos % 64;
                    if (word_idx < first_mask->size && (first_mask->bits[word_idx] & (1ULL << bit_idx))) {
                        bool match = true;
                        for (size_t j = 1; j < pattern_len && match; j++) {
                            if (pos + j >= text_len_size || dna_text[pos + j] != pattern[j]) {
                                match = false;
                            }
                        }
                        if (match) total_matches++;
                    }
                }
            }
            optimized_text_destroy(opt_text);
        }
        clock_t end2 = clock();
        double full_search_time = ((double)(end2 - start2)) / CLOCKS_PER_SEC * 1000.0;
        
        double ratio = (first_match_pos >= 0) ? (double)first_match_pos / text_len : 1.0;
        
        printf("%-12d %-15.6f %-15.6f %-15d %-15.2f%%\n",
               text_len, first_only_time, full_search_time, 
               first_match_pos, ratio * 100);
        
        free(dna_text);
    }
    
    printf("\n");
}

int main() {
    printf("FlowRegex マッチ結果分析\n");
    printf("========================\n\n");
    
    analyze_match_results();
    analyze_early_termination();
    
    printf("分析完了\n");
    return 0;
}
