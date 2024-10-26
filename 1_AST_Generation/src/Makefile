# makefile
all: parser

parser: parser.o lex.o node/node.o
	g++ -o parser parser.o lex.o node/node.o -ll

parser.o: parser.tab.c
	g++ -o parser.o -c parser.tab.c

parser.tab.c: parser.y
	bison -d parser.y

lex.o: lex.yy.c
	g++ -o lex.o -c lex.yy.c -ll

lex.yy.c: lexer.l
	flex lexer.l

node/node.o: node/node.cpp node/node.h
	g++ -o node/node.o -c node/node.cpp

clean:
	rm -f *.o **/*.o parser parser.tab.c parser.tab.h lex.yy.c
