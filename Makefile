#
#	sudoku_valid	WJ125
#	Makefile
#

all: sudoku_valid sudoku_valid2

# use -g for debug builds
.s.o:
	as -g -o $@ $<

sudoku_valid: sudoku_valid.o
	ld -o $@ $^

sudoku_valid2.o: sudoku_valid2.s sudoku.txt
sudoku_valid2: sudoku_valid2.o
	ld -o $@ $^

clean:
	rm -f sudoku_valid sudoku_valid.o sudoku_valid2 sudoku_valid2.o

# EOB
