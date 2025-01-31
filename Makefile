#
#	sudoku_valid	WJ125
#	Makefile
#

all: sudoku_valid

.s.o:
	as -o $@ $<

sudoku_valid: sudoku_valid.o
	ld -s -o $@ $^

clean:
	rm -f sudoku_valid sudoku_valid.o

# EOB
