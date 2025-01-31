/*
    sudoku_valid.s        WJ125

    * program says whether (hardcoded) sudoku is valid or not
    * exit code 0 if valid
    * Linux aarch64

    Copyright (c) 2025 Walter de Jong <walter@heiho.net>

    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
    of the Software, and to permit persons to whom the Software is furnished to do
    so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

.data
s_hello:
    .ascii "hello, sudoku!\n"
len_hello = . - s_hello

s_valid:
    .ascii "The sudoku is valid!\n"
len_valid = . - s_valid

s_not_valid:
    .ascii "The sudoku is not valid ...\n"
len_not_valid = . - s_not_valid

s_invalid_digits:
    .ascii "The sudoku contains invalid digits\n"
len_invalid_digits = . - s_invalid_digits

s_invalid_row:
    .ascii "The sudoku contains an invalid row\n"
len_invalid_row = . - s_invalid_row

s_invalid_column:
    .ascii "The sudoku contains an invalid column\n"
len_invalid_column = . - s_invalid_column

s_invalid_block:
    .ascii "The sudoku contains an invalid block\n"
len_invalid_block = . - s_invalid_block

sudoku:
    .byte '7', '4', '5', '3', '2', '6', '9', '1', '8'
    .byte '1', '6', '2', '5', '8', '9', '4', '7', '3'
    .byte '8', '9', '3', '7', '1', '4', '6', '5', '2'

    .byte '6', '2', '7', '9', '5', '3', '1', '8', '4'
    .byte '9', '1', '8', '6', '4', '2', '7', '3', '5'
    .byte '5', '3', '4', '1', '7', '8', '2', '6', '9'

    .byte '3', '8', '9', '2', '6', '1', '5', '4', '7'
    .byte '4', '5', '1', '8', '9', '7', '3', '2', '6'
    .byte '2', '7', '6', '4', '3', '5', '8', '9', '1'

.equ DIM, 9
.equ BLOCK_DIM, 3
.equ NUM_BLOCKS, (DIM/BLOCK_DIM) * (DIM/BLOCK_DIM)

.equ SYS_exit, 93
.equ SYS_write, 64
.equ STDOUT, 1


.text

.global _start

_start:
    ldr x0, =s_hello
    mov x1, len_hello
    bl fn_print

    /* check whether soduku is valid */
    ldr x0, =sudoku
    bl fn_is_sudoku_valid
    cbz x0, print_valid

    /* the sudoku is not valid */
    ldr x0, =s_not_valid
    mov x1, len_not_valid
    bl fn_print

    mov x0, #255
    bl fn_exit

print_valid:
    /* the sudoku is valid */
    ldr x0, =s_valid
    mov x1, len_valid
    bl fn_print

    mov x0, #0
    bl fn_exit


/*
   function: print
   x0 is address of string
   x1 is length of string

   Returns return code of write syscall in x0
*/
fn_print:
    mov x2, x1
    mov x1, x0
    mov x0, STDOUT
    mov w8, SYS_write
    svc #0
    ret


/*
    function: exit
    x0 is exit code

    This function exits the program and does not return
*/
fn_exit:
    mov w8, SYS_exit
    svc #0


/*
    function: is_sudoku_valid
    x0 is address of 81 (9x9, or DIM x DIM) sudoku bytes (ASCII numbers)

    Returns zero if sudoku is valid

    The sudoku is valid if:
    - contains valid digits
    - all 9 rows are valid
    - all 9 columns are valid
    - all 9 blocks are valid
*/
fn_is_sudoku_valid:
    stp x29, x30, [sp, #-32]!
    stp x19, x20, [sp, #16]

    mov x19, x0

    /* check digits */
    bl fn_check_digits
    cbnz x0, is_sudoku_valid_nope_invalid_digits

    /* check rows */
    mov x20, #0
is_sudoku_valid_next_row:
    mov x0, x19
    mov x1, x20
    bl fn_is_row_valid
    cbnz x0, is_sudoku_valid_nope_invalid_row

    add x20, x20, #1
    cmp x20, DIM
    blt is_sudoku_valid_next_row

    /* check columns */
    mov x20, #0
is_sudoku_valid_next_column:
    mov x0, x19
    mov x1, x20
    bl fn_is_column_valid
    cbnz x0, is_sudoku_valid_nope_invalid_column

    add x20, x20, #1
    cmp x20, DIM
    blt is_sudoku_valid_next_column

    /* check blocks */
    mov x20, #0
is_sudoku_valid_next_block:
    mov x0, x19
    mov x1, x20
    bl fn_is_block_valid
    cbnz x0, is_sudoku_valid_nope_invalid_block

    add x20, x20, #1
    cmp x20, NUM_BLOCKS
    blt is_sudoku_valid_next_block

    /* it is a valid sudoku */

    mov x0, #0
is_sudoku_valid_ret:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

is_sudoku_valid_nope_invalid_digits:
    /* print error: invalid digits */
    ldr x0, =s_invalid_digits
    mov x1, len_invalid_digits
    bl fn_print

    mov x0, #-1
    b is_sudoku_valid_ret

is_sudoku_valid_nope_invalid_row:
    /* print error: invalid row */
    ldr x0, =s_invalid_row
    mov x1, len_invalid_row
    bl fn_print

    mov x0, #-1
    b is_sudoku_valid_ret

is_sudoku_valid_nope_invalid_column:
    /* print error: invalid column */
    ldr x0, =s_invalid_column
    mov x1, len_invalid_column
    bl fn_print

    mov x0, #-1
    b is_sudoku_valid_ret

is_sudoku_valid_nope_invalid_block:
    /* print error: invalid block */
    ldr x0, =s_invalid_block
    mov x1, len_invalid_block
    bl fn_print

    mov x0, #-1
    b is_sudoku_valid_ret


/*
    function check_digits
    x0 is base address of 9x9 sudoku in ASCII bytes

    This function checks whether all digits in the sudoku
    are between '1'..'9'

    Returns zero if valid
*/
fn_check_digits:
    stp x29, x30, [sp, #-32]!
    stp x19, x20, [sp, #16]

    mov x10, x0
    mov x20, #0
    
check_digits_loop:
    ldrb w0, [x19], #1
    bl fn_is_digit
    cbnz x0, check_digits_nope

    add x20, x20, #1
    cmp x20, DIM * DIM
    blt check_digits_loop

    mov x0, #0
check_digits_ret:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

check_digits_nope:
    mov x0, #-1
    b check_digits_ret


/*
   function is_digit
   x0 is a sudoku ASCII digit '1'..'9'

   Returns zero if digit is valid
*/
fn_is_digit:
    cmp x0, '0'
    bls is_digit_nope

    cmp x0, '9'
    bhi is_digit_nope

    mov x0, #0
is_digit_ret:
    ret

is_digit_nope:
    mov x0, #-1
    b is_digit_ret


/*
    function is_row_valid
    x0 is base address of 9x9 sudoku
    x1 is row number

    The row is valid if each digit occurs exactly once

    Returns zero if row is valid
*/
fn_is_row_valid:
    /*
        make x2 the base of the row;
        x2 = row (x1) * 9 + base (x0)
    */
    mov x2, x1, lsl #3
    add x2, x2, x1
    add x2, x2, x0

    mov x1, #1                  /* x1 is used as "immediate" shift value */
    mov x4, #0                  /* x4 will hold 9 set bits, one for each digit */
    mov x9, #0                  /* x9 is loop counter */
is_row_valid_loop:
    ldrb w0, [x2], #1
    sub w0, w0, '0'
    lslv x0, x1, x0             /* x0 = (1 << [row byte]) */
    orr x4, x4, x0

    add x9, x9, #1
    cmp x9, DIM
    blt is_row_valid_loop

    cmp w4, 0b01111111110       /* 9 bits must be set, bit zero remains unset */
    bne is_row_valid_nope

    mov x0, #0
is_row_valid_ret:
    ret

is_row_valid_nope:
    mov x0, #-1
    b is_row_valid_ret


/*
    function is_column_valid
    x0 is base address of 9x9 sudoku
    x1 is column number

    Returns zero if column is valid
*/
fn_is_column_valid:
    /*
        make x2 the base of the column;
        x2 = base (x0) + column (x1)
    */
    add x2, x0, x1

    mov x1, #1                  /* x1 is used as "immediate" shift value */
    mov x4, #0                  /* x4 will hold 9 set bits, one for each digit */
    mov x9, #0                  /* x9 is loop counter */
is_column_valid_loop:
    ldrb w0, [x2], #9
    sub w0, w0, '0'
    lslv x0, x1, x0             /* x0 = (1 << [row byte]) */
    orr x4, x4, x0

    add x9, x9, #1
    cmp x9, DIM
    blt is_column_valid_loop

    cmp w4, 0b01111111110       /* 9 bits must be set, bit zero remains unset */
    bne is_column_valid_nope

    mov x0, #0
is_column_valid_ret:
    ret

is_column_valid_nope:
    mov x0, #-1
    b is_column_valid_ret


/*
    function is_block_valid
    x0 is base address of 9x9 sudoku
    x1 is block number (top left is #0)

    Returns zero if block is valid
*/
fn_is_block_valid:
    /*
        make x2 the base of the block
        x2 = block (x1) / (DIM/BLOCK_DIM) * (DIM * BLOCK_DIM) + block (x1) % (DIM/BLOCK_DIM) * BLOCK_DIM + base (x0)
    */
    mov x3, #3
    udiv x4, x1, x3
    msub x5, x4, x3, x1

    /* x2 = (block / 3) * (9 * 3) */
    mov x3, (DIM * BLOCK_DIM)
    mul x2, x4, x3

    /* x2 += (block % 3) * 3 */
    lsl x6, x5, #1
    add x2, x2, x6
    add x2, x2, x5

    /* x2 += base */
    add x2, x2, x0

    /*
        now check the block under x2

        check [x2], [x2+1], [x2+2]
        x2 += 9
        check [x2], [x2+1], [x2+2]
        x2 += 9
        check [x2], [x2+1], [x2+2]
    */
    mov x1, #1                  /* x1 is used as "immediate" shift value */
    mov x4, #0                  /* x4 will hold 9 set bits, one for each digit */

    ldrb w0, [x2], #1
    sub w0, w0, '0'
    lslv x0, x1, x0             /* x0 = (1 << [row byte]) */
    orr x4, x4, x0

    ldrb w0, [x2], #1
    sub w0, w0, '0'
    lslv x0, x1, x0             /* x0 = (1 << [row byte]) */
    orr x4, x4, x0

    ldrb w0, [x2], #1
    sub w0, w0, '0'
    lslv x0, x1, x0             /* x0 = (1 << [row byte]) */
    orr x4, x4, x0

    add x2, x2, #6              /* next block line */

    ldrb w0, [x2], #1
    sub w0, w0, '0'
    lslv x0, x1, x0             /* x0 = (1 << [row byte]) */
    orr x4, x4, x0

    ldrb w0, [x2], #1
    sub w0, w0, '0'
    lslv x0, x1, x0             /* x0 = (1 << [row byte]) */
    orr x4, x4, x0

    ldrb w0, [x2], #1
    sub w0, w0, '0'
    lslv x0, x1, x0             /* x0 = (1 << [row byte]) */
    orr x4, x4, x0

    add x2, x2, #6              /* next block line */

    ldrb w0, [x2], #1
    sub w0, w0, '0'
    lslv x0, x1, x0             /* x0 = (1 << [row byte]) */
    orr x4, x4, x0

    ldrb w0, [x2], #1
    sub w0, w0, '0'
    lslv x0, x1, x0             /* x0 = (1 << [row byte]) */
    orr x4, x4, x0

    ldrb w0, [x2], #1
    sub w0, w0, '0'
    lslv x0, x1, x0             /* x0 = (1 << [row byte]) */
    orr x4, x4, x0

    cmp w4, 0b01111111110       /* 9 bits must be set, bit zero remains unset */
    bne is_block_valid_nope

    mov x0, #0
is_block_valid_ret:
    ret

is_block_valid_nope:
    mov x0, #-1
    b is_block_valid_ret

/* EOB */
