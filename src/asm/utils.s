//Prints binary representation of 64bit integer
//takes x0 as int64_t: this is also quite inefficient but is only used for debugging
print_binary64:
    stp fp, lr, [sp, #-16]!
    mov fp, sp

    mov x5, #0x40
    mov x6, x0

1:
    //calculate bit at index x5
    sub x3, x5, #1
    lsrv x0, x6, x3   
    and x1, x0, #0x01

    //add char 0 to get ascii rep of digit
    add x1, x1, #0x30

    bl print_char

    subs x5, x5, #1
    b.ne 1b
    
    mov w1, #0x0A //new line char
    bl print_char
    
    ldp fp, lr, [sp], #16
    ret