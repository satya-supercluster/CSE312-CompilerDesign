# makefile
all: parser

parser: parser.o lex.o node/node.o symbol_table/symbol_table.o 3ac/3ac.o type_utils/type_utils.o
	g++ -o parser parser.o lex.o node/node.o symbol_table/symbol_table.o type_utils/type_utils.o 3ac/3ac.o -ll

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

symbol_table/symbol_table.o: symbol_table/symbol_table.cpp symbol_table/symbol_table.h
	g++ -o symbol_table/symbol_table.o -c symbol_table/symbol_table.cpp

3ac/3ac.o: 3ac/3ac.cpp 3ac/3ac.h
	g++ -o 3ac/3ac.o -c 3ac/3ac.cpp

type_utils/type_utils.o: type_utils/type_utils.cpp type_utils/type_utils.h
	g++ -o type_utils/type_utils.o -c type_utils/type_utils.cpp

clean:
	rm -f *.o **/*.o parser parser.tab.c parser.tab.h lex.yy.c
