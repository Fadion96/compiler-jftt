.PHONY: clean

all: kompilator

kompilator:
		bison -d parser.y -o parser.cpp
		flex -o lexer.cpp lexer.l
		g++ -std=c++11 parser.cpp lexer.cpp -o kompilator

clean:
	rm -f *.o kompilator parser.cpp parser.hpp lexer.cpp
