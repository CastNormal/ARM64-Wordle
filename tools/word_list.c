#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>

#define WORD_COUNT 14855

int main() {
    FILE *word_file = fopen("words.txt", "r");
    FILE *comp_file = fopen("tools/int32-words.bin", "wb");

    char c;
    int32_t word = 0;
    int i = 0;
    int32_t words[WORD_COUNT];

    while ((c = fgetc(word_file)) != EOF) {
        if (c == '\n') {
            words[i++] = word;
            word = 0;
            continue;
        }

        word <<= 5;
        word += c - 'a';
    }

    fwrite(words, sizeof(int32_t), WORD_COUNT, comp_file);
    fclose(word_file);
    fclose(comp_file);
    return 0;
}