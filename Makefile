all: bison flex gcc
	@echo "Done."

bison: parser.y
	bison parser.y

flex: scanner.l
	flex scanner.l

gcc: scanner.c parser.c
	gcc -Wall -o trab3 scanner.c parser.c tables.c -ly

clean:
	@rm -f *.o *.output scanner.c parser.h parser.c trab3
