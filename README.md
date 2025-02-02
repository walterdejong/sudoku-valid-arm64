sudoku-valid-arm64
==================

Three programs, namely `sudoku_valid`,  `sudoku_valid2`, `sudoku_valid3`.

These programs implement a LeetCode challenge: write `is_sudoku_valid`
in assembly language. I'm using Linux/aarch64; this code was written on
a raspberry pi 4, but may also compile and run on other Linux/aarch64 systems.

```
    7 4 5  3 2 6  9 1 8
    1 6 2  5 8 9  4 7 3
    8 9 3  7 1 4  6 5 2

    6 2 7  9 5 3  1 8 4
    9 1 8  6 4 2  7 3 5
    5 3 4  1 7 8  2 6 9

    3 8 9  2 6 1  5 4 7
    4 5 1  8 9 7  3 2 6
    2 7 6  4 3 5  8 9 1
```

A sudoku is a puzzle consisting of a 9x9 grid, containing the numbers
1 to 9. The grid is subdivided into (nine) 3x3 blocks.
A soduku is valid if the following conditions are met:
- each row contains only and exactly the numbers 1 to 9.
- each column contains only and exactly the numbers 1 to 9.
- each 3x3 sub-block contains only and exactly the numbers 1 to 9.

The program only checks whether the given sudoku is valid; it is not
a sudoku-solver.

## Implementation details

### sudoku_valid
In the first program, `sudoku_valid`, the numbers of the sudoku puzzle
are hardcoded into the program as ASCII bytes.

The program first checks whether all numbers are indeed within this range.
Consequently the other subroutines safely assume any byte in the puzzle
are an ASCII digit, and subtract `'0'` to get the value of the digit.

To determine whether all digits are present, we use nine bits that get
shifted into a register. Finally, the register must have all nine bits
set, for all digits to be present.

The puzzle dimensions are numeric constants, but they can't be changed
trivially because some integer multiplications/divisions are coded
with shifts.

### sudoku_valid2
The second program includes the file `sudoku.txt` into the source, and
it gets compiled-in.

It has a more straightforward coding style; in case of error, simply bail
out with `fatal`.

Checking rows now loads 8 bytes at once into a register. Because a sudoku
row has 9 digits, it loads the 9th digit separately.

Checking blocks now uses a table with offsets to blocks, and the subroutine
that checks a block has been unrolled for easiness.

## sudoku_valid3
The third incarnation loads the file `sudoku.txt` via Linux system calls.

It parses the file into a raw sequence of bytes. For verification,
it prints the loaded sudoku to the screen.

Next, it transposes the columns into a horizontal layout, and the 3x3 blocks
are also stored in a horizontal layout. Checking the puzzle can now be done
by one and the same subroutine, that simply checks "data lines" of 9 bytes.

In the 3rd program the Linux-specific code was moved to `linux.s`,
which may aid in porting to other platforms.

## Copyright and License
Copyright (c) 2025 Walter de Jong <walter@heiho.net>

This software is freely available under terms described in the MIT license.
