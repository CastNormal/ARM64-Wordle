#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>
#include <stdbool.h>

#define WORD_SIZE 5
#define GUESS_COUNT 6
#define WORD_COUNT 14855
#define GREEN_LETTER '#'
#define YELLOW_LETTER '?'
#define RED_LETTER 'X'


int32_t wrap_word(char *word) {
    int32_t rep = 0;

    for (int i = 0; i < WORD_SIZE; i++) {
        rep <<= 5;
        rep += word[i] - 'a';
    }

    return rep;
}

void unwrap_word(char *word, int32_t rep) {
    for (int i = 0; i < WORD_SIZE; i++) {
        char c = (rep & 0b11111) + 'a';
        word[(WORD_SIZE-1)-i] = c;
        rep >>= 5;
    }

    word[WORD_SIZE] = '\0';
}

bool bin_serach(int32_t *arr, uint32_t size, int32_t value) {
    int32_t a = 0, b = size-1;

    while (a <= b) {
        int c = a + ((b - a) >> 1);

        if (arr[c] == value) return true;

        if (arr[c] < value) a = c + 1;
        else b = c - 1;
    }
    
    return false;
}

int32_t getInput() {
    char buffer[WORD_SIZE+1];

    fgets(buffer, (WORD_SIZE+1)*sizeof(char), stdin);

    //check if the newline was NOT read
    char c;
    if (buffer[WORD_SIZE] != '\n') while ((c = getchar()) != '\n' && c != EOF);

    //make sure end like op is at the end
    buffer[WORD_SIZE] = '\0';

    return wrap_word(buffer);
}

int main() {
    FILE *file = fopen("tools/int32-words.bin", "rb");
    srand(time(NULL));

    if (file == NULL) return 1;

    register int32_t r1, r2;
    int32_t words[WORD_COUNT];
    fread(words, sizeof(int32_t), WORD_COUNT, file);
    fclose(file);

    //get hidden word
    int wi = rand() % WORD_COUNT;
    r1 = words[wi];
    char mystery_word[6];
    unwrap_word(mystery_word, r1);
    
    printf("%ld\n", wrap_word("abcde"));

    //string for guesses

    for (int i = 0; i < GUESS_COUNT; i++) {
        int32_t word = getInput();

        //make sure word is valid
        while (!bin_serach(words, WORD_COUNT, word)) {
            printf("INVALID WORD!!! ABORT!!! ABORT MISSION!!!\n");
            word = getInput();
        }

        //check for greens
        register int8_t r22 = 0;

        //frequency map of each letter 2 bits per letter
        register int64_t r23 = 0;

        //go backwards sice letters are given backwards
        for (int j = WORD_SIZE-1; j >= 0; j--) {
            register int8_t r24 = ((r1 >> 5*j) & 0b11111); //letter at index j

            if (r24 == ((word >> 5*j) & 0b11111))
                r22 |= (1 << j);
            else 
                r23 += (1LL << ((int64_t)r24*2)); //lowkey could just bit shift the result by 1 but this is more readible
        }

        if (r22 == 0b11111) break; //win con

        //check for yellows
        register int8_t r24 = 0;

        for (int j = WORD_SIZE-1; j >= 0; j--) {

            if ((r23 >> (word >> 5*j)*2) & 0b11) {
                r23 -= (1LL << (((int64_t)(word >> 5*j) & 0b11111)*2));
                r24 |= (1 << j);
            }
    
            //print letters positions
            printf("%c", ((r22 >> j) & 1) ? GREEN_LETTER : ((r24 >> j) & 1) ? YELLOW_LETTER : RED_LETTER);
        }

        printf("\n");
    }

    printf("The mystery word was %s!\n", mystery_word);
    return 0;
}