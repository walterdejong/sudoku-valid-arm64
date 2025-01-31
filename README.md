sudoku-valid-arm64
==================

This program implements a leet-code challenge: implement `is_sudoku_valid`
in assembly language. Just for kicks, I picked Linux/aarch64; this code
was written on a raspberry pi 4, but just might compile and run on other
Linux/aarch64 systems.

A sudoku is a puzzle consisting of a 9x9 grid, containing the numbers
1 to 9. The grid is subdivided into (nine) 3x3 blocks.
A soduku is valid if the following conditions are met:
- each row contains only and exactly the numbers 1 to 9.
- each column contains only and exactly the numbers 1 to 9.
- each 3x3 sub-block contains only and exactly the numbers 1 to 9.

This program only checks whether the given sudoku is valid; it is not
a sudoku-solver.

## Implementation
The exact numbers of the sudoku puzzle are hardcoded into the program
as ASCII bytes, `'1'` to `'9'`.

The program first checks whether all numbers are indeed within this range.
Consequently the other subroutines safely assume any byte in the puzzle
are an ASCII digit, and subtract `'0'` to get the value of the digit.

To determine whether all digits are present, we use nine bits that get
shifted into a register. Finally, the register must have all nine bits
set, for all digits to be present.

The puzzle dimensions are numeric constants, but they can't be changed
trivially because some integer multiplications/divisions are coded
with shifts.

My first aarch64 code, really. Remember, aarch64 conventions:
- function parameters in x0 - x3
- return value in x0
- x0 - x17 volatile registers
- x18 is reserved
- x19 - x28 non-volatile registers
- x29 frame pointer
- x30 link register


## Copyright and License
Copyright (c) 2025 Walter de Jong <walter@heiho.net>

This software is freely available under terms described in the MIT license.
