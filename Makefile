.PHONY: clean

all: kompilator

kompilator:
		bison -d parser.y -o parser.tab.cpp
		flex -o lexer.cpp lexer.l
		g++ -std=c++11 parser.tab.cpp lexer.cpp -o kompilator

clean:
	rm -f *.o kompilator parser.tab.cpp parser.tab.hpp lexer.cpp
