#include <inttypes.h>

void print_binary32(int32_t n) {
    for (int i = 31; i >= 0; i--) {
        int64_t bit = (n >> i) & 1;
        printf("%d", (int)bit);
        if (i % 5 == 0) printf(" "); //Space every 5 bits for readability (ignore first 7)
    }
    printf("\n");
}

void print_binary64(int64_t n) {
    for (int i = 63; i >= 0; i--) {
        int64_t bit = (n >> i) & 1;
        printf("%d", (int)bit);
        if (i % 4 == 0) printf(" "); //Space every 5 bits for readability (ignore first 7)
    }
    printf("\n");
}