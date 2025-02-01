/*
    sudoku_valid2.s       WJ125

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

/*
    definition of the sudoku puzzle
    There may be spaces and newlines in this block
*/
sudoku:
    .ascii "7 4 5  3 2 6  9 1 8"
    .ascii "1 6 2  5 8 9  4 7 3"
    .ascii "8 9 3  7 1 4  6 5 2"

    .ascii "6 2 7  9 5 3  1 8 4"
    .ascii "9 1 8  6 4 2  7 3 5"
    .ascii "5 3 4  1 7 8  2 6 9"

    .ascii "3 8 9  2 6 1  5 4 7"
    .ascii "4 5 1  8 9 7  3 2 6"
    .ascii "2 7 6  4 3 5  8 9 1"

s_valid:
    .ascii "the sudoku is valid!\n"
len_valid = . - s_valid

s_spellcheck_invalid:
    .ascii "error: spellcheck: invalid sudoku\n"
len_spellcheck_invalid = . - s_spellcheck_invalid

s_invalid_row:
    .ascii "error: sudoku contains an invalid row\n"
len_invalid_row = . - s_invalid_row

s_invalid_column:
    .ascii "error: sudoku contains an invalid column\n"
len_invalid_column = . - s_invalid_column

s_invalid_block:
    .ascii "error: sudoku contains an invalid block\n"
len_invalid_block = . - s_invalid_block

/*
    offsets to blocks
*/
d_block_offsets:
    .word 0, 3, 6
    .word 27, 30, 33
    .word 54, 57, 60

.bss

/*
    the ASCII sudoku gets converted to 'raw' bytes for convenience
    81 bytes for 9x9 sudoku grid
*/
sudoku_raw:
    .space 81


.equ SYS_exit, 93
.equ SYS_write, 64
.equ STDOUT, 1
.equ STDERR, 2

.text

.global _start

_start:
    bl load_sudoku
    bl check_rows
    bl check_columns
    bl check_blocks

    /* if we got here, then the sudoku is valid */

    ldr x0, =s_valid
    mov x1, len_valid
    bl fn_print

    mov x0, #0
    b fn_exit

/*
    function: print
    x0 is address of message to print
    x1 is length of message

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
    function: printerr
    x0 is address of message to print to stderr
    x1 is length of message

    Returns return code of write syscall in x0
*/
fn_printerr:
    mov x2, x1
    mov x1, x0
    mov x0, STDERR
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
    function: fatal
    x0 is address of message to print to stderr
    x1 is length of message

    This "function" exits the program and does not return
*/
fatal:
    bl fn_printerr
    mov x0, #-1
    b fn_exit


/*
    `load_sudoku` converts the ASCII sudoku puzzle to 'raw' bytes

    It expects to see 81 ASCII digits between '1' and '9'
    There may be spaces and newlines in between
    The raw bytes are stored in `sudoku_raw`

    This function aborts with `fatal` if invalid
*/
load_sudoku:
    ldr x1, =sudoku
    ldr x2, =sudoku_raw

    mov x6, #1000               /* x6 is a loop guard */
    mov x7, #0                  /* x7 is digit counter */

spellcheck_loop:
    ldrb w0, [x1], #1

    sub x6, x6, #1              /* loop guard: prevent too many iterations */
    cbz x6, spellcheck_invalid

    cmp w0, ' '
    beq spellcheck_loop
    cmp w0, '\n'
    beq spellcheck_loop

    cmp w0, '1'
    blt spellcheck_invalid
    cmp w0, '9'
    bgt spellcheck_invalid

    sub w0, w0, '0'
    strb w0, [x2], #1

    add x7, x7, #1
    cmp x7, #81
    blt spellcheck_loop

    ret

spellcheck_invalid:
    ldr x0, =s_spellcheck_invalid
    mov x1, len_spellcheck_invalid
    b fatal


/*
    `check_rows` checks whether all rows are valid
    `sudoku_raw` must have been initialized earlier by `load_sudoku`

    A row is valid if each digit 1..9 occurs exactly once
    We set a bit in x6 for each digit
    The row is valid if 9 bits are set in x6
    Loop over 9 rows

    This function aborts with `fatal` if invalid
*/
check_rows:
    ldr x1, =sudoku_raw

    mov x9, #9                  /* we will check 9 rows */
check_row:
    mov x4, #1                  /* x4 is used for shifting (1 << byte) */
    mov x6, #0                  /* x6 holds bits for all digits */

    ldr x0, [x1], #8            /* load 8 bytes at once */
    mov x7, #8
check_row_digit:
    and x2, x0, #0xff           /* grab byte */
    lsr x0, x0, #8              /* shift byte out */
    lsl x2, x4, x2              /* x2 = (1 << byte) */
    orr x6, x6, x2              /* set bit for given digit in x6 */

    sub x7, x7, #1              /* do this 8 times, for 8 digits */
    cbnz x7, check_row_digit

    ldrb w2, [x1], #1           /* load 9th byte of row */
    lsl x2, x4, x2              /* x2 = (1 << byte) */
    orr x6, x6, x2              /* set bit for given digit in x6 */

    cmp x6, 0b01111111110       /* 9 bits must be set; bit #0 remains unset */
    bne check_rows_invalid

    sub x9, x9, #1
    cbnz x9, check_row          /* check the next row */

    ret

check_rows_invalid:
    ldr x0, =s_invalid_row
    mov x1, len_invalid_row
    b fatal


/*
    `check_columns` checks whether all columns are valid
    `sudoku_raw` must have been initialized earlier by `load_sudoku`

    A column is valid if each digit 1..9 occurs exactly once
    We set a bit in x6 for each digit
    The column is valid if 9 bits are set in x6
    Loop over 9 columns

    This function aborts with `fatal` if invalid
*/
check_columns:
    ldr x1, =sudoku_raw
    mov x2, x1                  /* keep copy of column start */

    mov x9, #9                  /* we will check 9 columns */
check_column:
    mov x4, #1                  /* x4 is used for shifting (1 << byte) */
    mov x6, #0                  /* x6 holds bits for all digits */

    mov x7, #9                  /* check 9 digits */
check_column_digit:
    ldrb w0, [x1], #9           /* load byte and skip over 9 bytes */

    lsl x0, x4, x0              /* x0 = (1 << byte) */
    orr x6, x6, x0              /* set bit for given digit in x6 */

    sub x7, x7, #1              /* do this 9 times, for 9 digits */
    cbnz x7, check_column_digit

    cmp x6, 0b01111111110       /* 9 bits must be set; bit #0 remains unset */
    bne check_columns_invalid

    add x2, x2, #1              /* move to next column */
    mov x1, x2
    sub x9, x9, #1
    cbnz x9, check_column       /* check the next column */

    ret

check_columns_invalid:
    ldr x0, =s_invalid_column
    mov x1, len_invalid_column
    b fatal


/*
    `check_blocks` checks whether all blocks are valid
    `sudoku_raw` must have been initialized earlier by `load_sudoku`

    This function aborts with `fatal` if invalid
*/
check_blocks:
    stp x29, x30, [sp, #-32]!
    stp x19, x20, [sp, #16]

    /*
        check 9 blocks using a table containing block offsets
    */
    ldr x20, =d_block_offsets
    mov x19, #9                 /* there are 9 blocks */

check_next_block:
    ldr x0, =sudoku_raw
    ldrh w1, [x20], #4          /* load block offset */
    add x0, x0, x1
    bl check_block

    sub x19, x19, #1
    cbnz x19, check_next_block

    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret


/*
    `check_block` checks whether a single 3x3 block is valid
    in: x0 is address pointing at the block

    A 3x3 block is valid if each digit 1..9 occurs exactly once
    We set a bit in x6 for each digit
    The block is valid if 9 bits are set in x6

    This function aborts with `fatal` if invalid
*/
check_block:
    mov x1, x0

    mov x4, #1                  /* x4 is used for shifting (1 << byte) */
    mov x6, #0                  /* x6 holds bits for all digits */

    /*
        in an unrolled fashion, we will do 3 digits,
        move to the next line, do 3 digits,
        move to the next line, and do 3 digits.
    */

    ldrb w0, [x1], #1
    lsl x0, x4, x0              /* x0 = (1 << byte) */
    orr x6, x6, x0              /* set bit for given digit in x6 */

    ldrb w0, [x1], #1
    lsl x0, x4, x0              /* x0 = (1 << byte) */
    orr x6, x6, x0              /* set bit for given digit in x6 */

    ldrb w0, [x1], #1
    lsl x0, x4, x0              /* x0 = (1 << byte) */
    orr x6, x6, x0              /* set bit for given digit in x6 */

    add x1, x1, #6              /* move to next line */

    ldrb w0, [x1], #1
    lsl x0, x4, x0              /* x0 = (1 << byte) */
    orr x6, x6, x0              /* set bit for given digit in x6 */

    ldrb w0, [x1], #1
    lsl x0, x4, x0              /* x0 = (1 << byte) */
    orr x6, x6, x0              /* set bit for given digit in x6 */

    ldrb w0, [x1], #1
    lsl x0, x4, x0              /* x0 = (1 << byte) */
    orr x6, x6, x0              /* set bit for given digit in x6 */

    add x1, x1, #6              /* move to next line */

    ldrb w0, [x1], #1
    lsl x0, x4, x0              /* x0 = (1 << byte) */
    orr x6, x6, x0              /* set bit for given digit in x6 */

    ldrb w0, [x1], #1
    lsl x0, x4, x0              /* x0 = (1 << byte) */
    orr x6, x6, x0              /* set bit for given digit in x6 */

    ldrb w0, [x1], #1
    lsl x0, x4, x0              /* x0 = (1 << byte) */
    orr x6, x6, x0              /* set bit for given digit in x6 */

    cmp x6, 0b01111111110       /* 9 bits must be set; bit #0 remains unset */
    bne check_block_invalid

    ret

check_block_invalid:
    ldr x0, =s_invalid_block
    mov x1, len_invalid_block
    b fatal


/* EOB */
