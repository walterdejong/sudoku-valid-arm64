/*
    sudoku_valid3.s     WJ125

    * is-sudoku-valid aarch64

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

s_loading:
    .ascii "loading: sudoku.txt\n\n"
len_loading = . - s_loading

s_filename:
    .asciz "sudoku.txt"

s_open_failed:
    .ascii "error: failed to open: sudoku.txt\n"
len_open_failed = . - s_open_failed

s_read_failed:
    .ascii "error: failed to read: sudoku.txt\n"
len_read_failed = . - s_read_failed

s_parse_invalid_sudoku:
    .ascii "error: parse error: invalid sudoku\n"
len_parse_invalid_sudoku = . - s_parse_invalid_sudoku

s_valid:
    .ascii "\nthe sudoku is valid!\n"
len_valid = . - s_valid

s_invalid:
    .ascii "\nthe sudoku is not valid ...\n"
len_invalid = . - s_invalid

/*
    offsets to 3x3 blocks
*/
d_block_offsets:
    .word 0, 3, 6
    .word 27, 30, 33
    .word 54, 57, 60

.bss

/*
    b_sudoku is the buffer where we load the file data "sudoku.txt"
*/
.equ BUFSIZE, 512
.lcomm b_sudoku, BUFSIZE
.align 4

/*
    we store sudoku digits as bytes
    the complete sudoku has 9 rows
    Additionally,
    we layout nine columns horizontally in lines of 9 bytes each
    we layout nine blocks horizontally in lines of 9 bytes each
*/
.equ DATA_LINE, 9
.equ NINE_LINES, (9 * DATA_LINE)
.lcomm b_rows, NINE_LINES
.lcomm b_columns, NINE_LINES
.lcomm b_blocks, NINE_LINES
.align 4

.lcomm b_printbuf, 32

.equ STDOUT, 1
.equ STDERR, 2


.text
.global _start

_start:
    mov x0, STDOUT
    ldr x1, =s_loading
    mov x2, len_loading
    bl sys_write

    ldr x0, =s_filename
    bl load_file

    /* x0 is length of b_sudoku */

    bl parse_sudoku
    bl print_sudoku
    bl check_sudoku

    /* if we got here, then the sudoku is valid */

    mov x0, STDOUT
    ldr x1, =s_valid
    mov x2, len_valid
    bl sys_write

    /* clean exit program */
    mov w0, wzr
    b sys_exit


/*
    proc load_file: load "sudoku.txt" into buffer b_sudoku
    x0 is filename

    Returns number of bytes read;
    the length of b_sudoku

    Aborts the program with error message on I/O error
*/
.type load_file, @function
load_file:
    stp x29, x30, [sp, #-16]!

    /* open file 'sudoku.txt' */
    bl lib_open_readonly

    /* if negative, then error */
    tbnz x0, #63, open_error

    /* x0/x9 is file descriptor */
    mov x9, x0

    /* read file */
    ldr x1, =b_sudoku
    mov x2, BUFSIZE
    bl sys_read

    /* if negative, then error */
    tbnz x0, #63, read_error

    /* x0/x10 is number of bytes read */
    mov x10, x0

    /* close file */
    mov x0, x9
    bl sys_close

    /* return number of bytes read */
    mov x0, x10
    ldp x29, x30, [sp], #16
    ret

open_error:
    ldr x0, =s_open_failed
    mov x1, len_open_failed
    b fatal

read_error:
    ldr x0, =s_read_failed
    mov x1, len_read_failed
    b fatal


/*
    proc fatal: write message to stderr and exit -1
    x0 is address of message
    x1 is length of message

    This function exits the program and does not return
*/
.type fatal, @function
fatal:
    mov x2, x1
    mov x1, x0
    mov x0, STDERR
    bl sys_write

    mvn w0, wzr
    b sys_exit


/*
    proc parse_sudoku: parse ASCII b_sudoku into b_rows, b_columns, b_blocks,
    x0 is length of b_sudoku

    Aborts the program with error message on error
*/
.type parse_sudoku, @function
parse_sudoku:
    stp x29, x30, [sp, #-16]!

    mov x16, x0                 /* x0/x16 := length of buffer */
    bl parse_sudoku_rows
    bl make_layout_columns
    bl make_layout_blocks

    ldp x29, x30, [sp], #-16
    ret

/*
    proc parse_sudoku: parse the ASCII sudoku into b_rows
    x0 is length of b_sudoku

    Aborts the program with error message on error
*/
parse_sudoku_rows:
    ldr x1, =b_sudoku
    ldr x2, =b_rows

    mov x9, xzr                 /* x9 := number of collected digits in puzzle */
    mov x10, x0                 /* x10 := length of b_sudoku */

parse_loop:
    cbz x10, parse_end_of_buffer
    sub x10, x10, #1

    ldrb w0, [x1], #1
    cmp x0, ' '
    beq parse_loop
    cmp x0, '\t'
    beq parse_loop
    cmp x0, '\n'
    beq parse_loop
    cmp x0, '\r'
    beq parse_loop

    cmp x0, '_'
    beq parse_empty_cell

    cmp x0, '1'
    blt parse_error
    cmp x0, '9'
    bgt parse_error

    sub x0, x0, '0'             /* x0 := digit */
parse_store_digit:
    add x9, x9, #1
    /*
        if x9 > 81 then we would overrun the buffer; do not store it
    */
    cmp x9, #81
    bgt parse_error

    strb w0, [x2], #1           /* store the digit */
    b parse_loop

parse_empty_cell:
    mov w0, wzr                 /* store nul byte */
    b parse_store_digit

parse_end_of_buffer:
    /*
        we should have collected 81 digits by now
        otherwise, error
    */
    cmp x9, #81
    bne parse_error
    ret

parse_error:
    ldr x0, =s_parse_invalid_sudoku
    mov x1, len_parse_invalid_sudoku
    b fatal


/*
    proc print_sudoku
    prints the parsed sudoku that is in b_rows to stdout
*/
.type print_sudoku, @function
print_sudoku:
    stp x29, x30, [sp, #-32]!
    stp x19, x20, [sp, #16]

    mov x19, #9                 /* print 9 lines */
    ldr x1, =b_rows

print_sudoku_loop:
    ldr x2, =b_printbuf

    bl sprint_sudoku_3_digits

    /* sprint spaces */
    mov x0, ' '
    strb w0, [x2], #1
    strb w0, [x2], #1

    bl sprint_sudoku_3_digits

    /* sprint spaces */
    mov x0, ' '
    strb w0, [x2], #1
    strb w0, [x2], #1

    bl sprint_sudoku_3_digits

    /* sprint newline */
    mov x0, '\n'
    strb w0, [x2], #1

    cmp x19, #4                 /* after line 3 */
    beq print_sudoku_extra_newline
    cmp x19, #7                 /* after line 6 */
    bne print_sudoku_line

print_sudoku_extra_newline:
    /* add an extra newline after lines 3 and 6 */
    strb w0, [x2], #1

print_sudoku_line:
    mov x20, x1                 /* save b_rows pointer in x20 */
    /* print buffer to stdout */
    mov x0, STDOUT
    ldr x1, =b_printbuf
    sub x2, x2, x1              /* x2 is number of bytes to write */
    bl sys_write

    mov x1, x20                 /* x1 := b_rows pointer */

    sub x19, x19, #1            /* loop 9 times */
    cbnz x19, print_sudoku_loop

    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret


/*
    proc sprint_sudoku_3_digits
    prints next 3 digits into b_printbuf, with spaces in between

    x1 points into b_rows
    x2 points into b_printbuf
*/
.type sprint_sudoku_3_digits, @function
sprint_sudoku_3_digits:
    ldrb w0, [x1], #1
    add x0, x0, '0'             /* make ASCII digit */
    strb w0, [x2], #1

    mov x0, ' '
    strb w0, [x2], #1

    ldrb w0, [x1], #1
    add x0, x0, '0'             /* make ASCII digit */
    strb w0, [x2], #1

    mov x0, ' '
    strb w0, [x2], #1

    ldrb w0, [x1], #1
    add x0, x0, '0'             /* make ASCII digit */
    strb w0, [x2], #1

    ret

/*
    proc make_layout_columns
    takes the sudoku data from b_rows and
    stores the columns in horizontal layout in b_columns
*/
.type make_layout_columns, @function
make_layout_columns:
    ldr x2, =b_columns

    mov x3, xzr                 /* x3 := column number */

layout_next_column:
    ldr x1, =b_rows
    add x1, x1, x3

    mov x9, #9                  /* loop 9 times */
layout_column:
    ldrb w0, [x1], #1
    strb w0, [x2], #1
    add x1, x1, #8

    sub x9, x9, #1
    cbnz x9, layout_column

    /* skip to next column */
    add x3, x3, #1
    cmp x3, #9                  /* loop 9 times */
    blt layout_next_column

    ret


/*
    proc make_layout_blocks
    takes the sudoku data from b_rows and
    stores the blocks in horizontal layout in b_blocks
*/
.type make_layout_blocks, @function
make_layout_blocks:
    stp x29, x30, [sp, #-16]!

    ldr x2, =b_blocks
    ldr x16, =d_block_offsets

    mov x9, #9                  /* loop 9 times */
make_layout_blocks_loop:
    ldrh w3, [x16], #4
    ldr x1, =b_rows             /* point x1 at block */
    add x1, x1, x3
    bl make_layout_block

    sub x9, x9, #1
    cbnz x9, make_layout_blocks_loop

    ldp x29, x30, [sp], #16
    ret


/*
    proc make_layout_block
    takes the sudoku data from b_rows for a single block and
    stores it in horizontal layout in b_blocks
    x1 points into b_rows
    x2 points into b_blocks
*/
.type make_layout_block, @function
make_layout_block:
    ldrb w0, [x1], #1
    strb w0, [x2], #1

    ldrb w0, [x1], #1
    strb w0, [x2], #1

    ldrb w0, [x1], #1
    strb w0, [x2], #1

    add x1, x1, #6              /* skip to next line */

    ldrb w0, [x1], #1
    strb w0, [x2], #1

    ldrb w0, [x1], #1
    strb w0, [x2], #1

    ldrb w0, [x1], #1
    strb w0, [x2], #1

    add x1, x1, #6              /* skip to next line */

    ldrb w0, [x1], #1
    strb w0, [x2], #1

    ldrb w0, [x1], #1
    strb w0, [x2], #1

    ldrb w0, [x1], #1
    strb w0, [x2], #1

    ret


/*
    proc check_sudoku
    checks whether the sudoku puzzle is valid

    The data must have been layout properly into b_rows, b_columns, b_blocks

    Aborts the program with error message on error
*/
.type check_sudoku, @function
check_sudoku:
    stp x29, x30, [sp, #-16]!

    ldr x1, =b_rows
    bl check_datalines

    ldr x1, =b_columns
    bl check_datalines

    ldr x1, =b_blocks
    bl check_datalines

    ldp x29, x30, [sp], #16
    ret


/*
    proc check_datalines
    checks whether 9 datalines are valid
    x1 points at datalines

    Aborts the program with error message on error
*/
.type check_datalines, @function
check_datalines:
    stp x29, x30, [sp, #-16]!

    mov x16, #9

check_datalines_loop:
    bl check_dataline

    sub x16, x16, #1
    cbnz x16, check_datalines_loop

    ldp x29, x30, [sp], #16
    ret


/*
    proc check_dataline
    checks whether a dataline is valid
    x1 points at dataline

    Aborts the program with error message on error
*/
.type check_dataline, @function
check_dataline:
    /*
        Note: x16 is in use by check_datalines
    */

    mov x4, #1                  /* x4 is used for shifting (1 << byte) */
    mov x6, xzr                 /* x6 holds bits for all digits */

    ldr x0, [x1], #8            /* load 8 bytes at once */
    mov x7, #8
check_dataline_digit:
    and x2, x0, #0xff           /* grab byte */
    lsr x0, x0, #8              /* shift byte out */
    lsl x2, x4, x2              /* x2 = (1 << byte) */
    orr x6, x6, x2              /* set bit for given digit in x6 */

    sub x7, x7, #1              /* do this 8 times, for 8 digits */
    cbnz x7, check_dataline_digit

    ldrb w2, [x1], #1           /* load 9th byte of row */
    lsl x2, x4, x2              /* x2 = (1 << byte) */
    orr x6, x6, x2              /* set bit for given digit in x6 */

    cmp x6, 0b01111111110       /* 9 bits must be set; bit #0 remains unset */
    bne check_dataline_invalid

    ret

check_dataline_invalid:
    ldr x0, =s_invalid
    mov x1, len_invalid
    b fatal


/* EOB */
