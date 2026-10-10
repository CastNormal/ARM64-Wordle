.global main
.align 2

//Pseudo-random number generator (SplitMax64)
//Reference: https://rosettacode.org/wiki/Pseudo-random_numbers/Splitmix64
//Returns a random 64 bit integer
//Takes input x0 and returns x0
splitmix64:

    //Store 0x9e3779b97f4a7c15
    movz x1, #0x7c15
    movk x1, #0x7f4a, lsl #16
    movk x1, #0x79b9, lsl #32
    movk x1, #0x9e37, lsl #48

    add x0, x0, x1
    lsr x2, x0, #30
    eor x0, x0, x2

    //Store 0xbf58476d1ce4e5b9
    movz x3, #0xe5b9
    movk x3, #0x1ce4, lsl #16
    movk x3, #0x476d, lsl #32
    movk x3, #0xbf58, lsl #48

    mul x0, x0, x3
    lsr x2, x0, #27
    eor x0, x0, x2

    //Store 0x94d049bb133111eb
    movz x3, #0x11eb
    movk x3, #0x1331, lsl #16
    movk x3, #0x49bb, lsl #32
    movk x3, #0x94d0, lsl #48

    mul x0, x0, x3
    lsr x2, x0, #31
    eor x0, x0, x2

    ret

//takes x0 as int32_t repr of word
print_word: 
    sub sp, sp, #16 //will serve as buffer

    mov x3, #5 //5 letters per word
    mov x4, x0

1:
    and x1, x4, #0b11111
    add x1, x1, #0x61 //ASCII code for 'a'

    sub x2, x3, #1
    strb w1, [sp, x2]

    lsr x4, x4, #5

    subs x3, x3, #1
    b.ne 1b

    mov w1, #0x0A   //ASCII code for new char character
    strb w1, [sp, #5]

    //print
    mov x16, #4     //sys write
    mov x0, #1      //stdout
    mov x2, #6      //char length
    mov x1, sp
    svc 0x80

    add sp, sp, #16
    ret


//Prints a single character 
//Takes w1 as input
print_char:
    strb w1, [sp]

    //print
    mov x16, #4     //sys write  
    mov x0, #1      //stdout     
    mov x2, #1      //char length
    mov x1, sp
    svc 0x80

    ret

//Returns 32bit representation of word from console input
//Warning: Does not check if word is shorter or longer than 5 so might run into issues (should be no issues if its longer since it only take max 6 characters)
//Returns number representation in x0
word_from_input:
    stp fp, lr, [sp, #-16]!
    sub sp, sp, #16 //load string into stack

    mov x16, #3     //sys read
    mov x0, #0      //file desc
    mov x1, sp
    mov x2, #6      //string length
    svc #0x80
    
    mov x4, #0

    mov x5, #5
    mov x6, #0

1:                      //loop
    lsl x4, x4, #5
    ldrb w1, [sp, x6]
    sub w1, w1, #0x61   //ASCII code for 'a'
    add x4, x4, x1

    add x6, x6, #1
    cmp x6, x5
    b.ne 1b


    mov x0, x4

    add sp, sp, #16
    ldp fp, lr, [sp], #16
    ret

//Stores words from int32-words.bin into word_buffer
words_from_file:

    //open file
    adrp x0, file@PAGE
    add x0, x0, file@PAGEOFF
    mov x1, #0
    mov x2, #0
    mov x16, #5
    svc #0x80

    //save file descriptor
    mov x19, x0

    //read into buffer
    mov x0, x19
    adrp x1, word_buffer@PAGE
    add x1, x1, word_buffer@PAGEOFF
    ldr x2, =0xE81C
    mov x16, #3
    svc #0x80

    //close file
    mov x0, x19     //file descriptor
    mov x16, #6     //sys close
    svc #0x80

    ret

//Binary Search for word_buffer
//Takes x0 as input and returns boolean in x1
bin_search:
    adrp x3, word_buffer@PAGE
    add x3, x3, word_buffer@PAGEOFF

    mov x4, 0
    mov x5, #14854 //WORD_COUNT - 1

1:

    sub x7, x5, x4
    lsr x8, x7, #1
    add x6, x4, x8
    
    mov x2, #4
    mul x7, x6, x2

    ldr w2, [x3, x7]

    cmp x2, x0
    b.ne not1

    mov x1, #1
    ret

not1:

    cmp x2, x0
    b.lt else1

    sub x5, x6, #1
    b end_con

else1:
    add x4, x6, #1
    
end_con:


    cmp x4, x5
    b.le 1b

    mov x1, #0
    ret


//Entry point
main:
    bl words_from_file

    //use time as seed
    mrs x0, cntvct_el0
    bl splitmix64

    //mod
    mov x1, #14855
    udiv x2, x0, x1
    msub x1, x2, x1, x0
    
    mov x2, #4
    mul x1, x1, x2

    adrp x3, word_buffer@PAGE
    add x3, x3, word_buffer@PAGEOFF
    ldr w19, [x3, x1] //store secret word in x19

    //loop for 6 attempts 
    mov x21, #6

1:
    //get input and store in x20
    bl word_from_input
    mov x20, x0

    //check if word is valid
    bl bin_search

    cmp x1, #1
    b.eq valid

    mov x16, #4     //sys write  
    mov x0, #1      //stdout     
    mov x2, #17     //string length
    adrp x1, valid_word@PAGE
    add x1, x1, valid_word@PAGEOFF
    svc 0x80

    b 1b

valid:
    //frequency table
    mov x25, #0

    //greens
    mov x26, #0

    //green loop
    mov x22, #5
    2:
    sub x4, x22, #1
    //get letter of secret word
    mov x5, #5
    mul x6, x4, x5
    lsrv x7, x19, x6
    and x8, x7, #0b11111
    
    //get input letter
    lsrv x7, x20, x6
    and x9, x7, #0b11111
    //if and else statement
    cmp x8, x9
    b.ne else

    //if true
    mov x10, #1
    lslv x11, x10, x4
    add x26, x26, x11
    b if_done

else:
    mov x10, #2
    mul x11, x8, x10
    mov x10, #1
    lslv x12, x10, x11
    add x25, x25, x12

if_done: //skip over else
    subs x22, x22, #1
    b.ne 2b

    //check if won
    cmp x26, #0b11111
    b.eq win

    //yellows
    mov x27, #0

    //yellow loop
    mov x22, #5
3:
    sub x4, x22, #1

    mov x5, #5
    mul x6, x4, x5
    lsrv x7, x20, x6

    mov x8, #2
    mul x10, x7, x8
    lsrv x6, x25, x10
    and x5, x6, #0b11

    cmp x5, #0
    b.eq skip_if

    //if body
    mov x5, #5
    mul x6, x4, x5
    lsrv x7, x20, x6
    and x9, x7, #0b11111
    mul x10, x9, x8
    mov x6, #1
    lslv x5, x6, x10
    sub x25, x25, x5

    lslv x10, x6, x4
    add x27, x27, x10
        
skip_if:

    //determine letter color

    lsrv x5, x26, x4
    and x6, x5, #1
    cmp x6, #0
    b.eq not_green

    mov w1, #35 //green
    b exit_con

not_green:

    lsrv x5, x27, x4
    and x6, x5, #1
    cmp x6, #0
    b.eq not_yellow

    mov w1, #63 //yellow
    b exit_con

not_yellow:
    mov w1, #88 //red

exit_con:

    bl print_char

    subs x22, x22, #1
    b.ne 3b

    mov w1, #0x0A
    bl print_char

    subs x21, x21, 1
    b.ne 1b

lose:
    mov x16, #4
    mov x0, #1
    mov x2, #31
    adrp x1, lose_text@PAGE
    add x1, x1, lose_text@PAGEOFF
    svc 0x80

    mov x0, x19
    bl print_word

    b exit

win:
    mov x16, #4
    mov x0, #1
    mov x2, #30
    adrp x1, win_text@PAGE
    add x1, x1, win_text@PAGEOFF
    svc 0x80

    mov x0, x19
    bl print_word


exit:
    mov x16, #1
    mov x0, #0
    svc #0x80

.data
file:
    .ascii "tools/int32-words.bin"
.align 3
win_text:
    .ascii "You won! The mystery word was "
.align 3
lose_text:
    .ascii "You lost! The mystery word was "
.align 3
valid_word:
    .ascii "Not a valid word\n"
.bss
.align 3
word_buffer:
    .space 0xE81C //space for all 14855 words
