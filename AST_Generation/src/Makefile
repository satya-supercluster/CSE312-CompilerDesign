# makefile
all: parser

parser: parser.o lex.o node.o
	g++ -o parser parser.o lex.o node.o -ll

parser.o: parser.tab.c
	g++ -o parser.o -c parser.tab.c

parser.tab.c: parser.y
	bison -d parser.y

lex.o: lex.yy.c
	g++ -o lex.o -c lex.yy.c -ll

lex.yy.c: lexer.l
	flex lexer.l

node.o: node.cpp node.h
	g++ -o node.o -c node.cpp

clean:
	rm -f *.o parser parser.tab.c parser.tab.h lex.yy.c
