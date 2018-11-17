%{
	#define YYSTYPE std::string
	#include <iostream>
	#include <string>
	#include "identifier.h"

	int yylex();
	void yyerror(const char *s);
	extern int yylineno;
	extern FILE *yyin;
%}

%token DECLARE IN END
%token PID NUM
%token ASG
%token IF THEN ELSE ENDIF
%token WHILE DO ENDWHILE ENDDO
%token FOR FROM TO DOWNTO ENDFOR
%token READ WRITE
%token ADD SUB MULT DIV MOD
%token EQ NE LT GT LE GE
%token LB RB
%token SEMI COLON

%%

program:
		DECLARE declarations IN commands END
		{
			std::cout << "Koniec" << std::endl;
		}
		;

declarations:
		declarations PID SEMI
		{
			Identifier* id = new Identifier($2, IDE);
			std::cout << "Name: " << id->getName() << " Typ: " << id->getType() << std::endl;
		}
		| declarations PID LB NUM COLON NUM RB SEMI
		{
			Identifier* id = new Identifier($2, ARR, atoi(($4).c_str()), atoi(($6).c_str()));
			std::cout << "Name: " << id->getName() << " Typ: " << id->getType() << std::endl;

		}
		|
		;

commands:
		commands command
		| command
		;

command:
		identifier ASG expression SEMI
		{
			std::cout << "Przypisanie" << std::endl;
		}
		| IF condition THEN commands ELSE commands ENDIF
		{
			std::cout << "if else" << std::endl;
		}
		| IF condition THEN commands ENDIF
		{
			std::cout << "if" << std::endl;
		}
		| WHILE condition DO commands ENDWHILE
		{
			std::cout << "while" << std::endl;
		}
		| DO commands WHILE condition ENDDO
		{
			std::cout << "do while" << std::endl;
		}
		| FOR PID FROM value TO value DO commands ENDFOR
		{
			std::cout << "from to" << std::endl;
		}
		| FOR PID FROM value DOWNTO value DO command ENDFOR
		{
			std::cout << "from downto" << std::endl;
		}
		| READ identifier SEMI
		{
			std::cout << "read" << std::endl;
		}
		| WRITE value SEMI
		{
			std::cout << "write" << std::endl;
		}
		;

expression:
		value
		{
			std::cout << "value" << std::endl;
		}
		| value ADD value
		{
			std::cout << "+" << std::endl;
		}
		| value SUB value
		{
			std::cout << "-" << std::endl;
		}
		| value MULT value
		{
			std::cout << "*" << std::endl;
		}
		| value DIV value
		{
			std::cout << "/" << std::endl;
		}
		| value MOD value
		{
			std::cout << "%" << std::endl;
		}
		;

condition:
		value EQ value
		{
			std::cout << "equals" << std::endl;
		}
		| value NE value
		{
			std::cout << "not equals" << std::endl;
		}
		| value LT value
		{
			std::cout << "less" << std::endl;
		}
		| value GT value
		{
			std::cout << "great" << std::endl;
		}
		| value LE value
		{
			std::cout << "less eq" << std::endl;
		}
		| value GE value
		{
			std::cout << "great eq" << std::endl;
		}
		;

value:
		NUM
		{
			std::cout << "Liczba" << std::endl;
		}
		| identifier
		{
			std::cout << "id" << std::endl;
		}
		;

identifier:
		PID
		{
			std::cout << "id pid" << std::endl;
		}
		| PID LB PID RB
		{
			std::cout << "id arr pid" << std::endl;
		}
		| PID LB NUM RB
		{
			std::cout << "id arr num" << std::endl;
		}
		;

%%

void yyerror(char const *s) {
	cerr << "Error (" << yylineno << ") " << s << std::endl;
	exit(1);
}

int main(int argc, char **argv) {
	yyin = fopen(argv[1], "r");
	yyparse();
	fclose(yyin);
}
