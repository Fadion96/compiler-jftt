%{

	#include <iostream>
	#include <string>
	#include <cstring>
	#include <map>
	#include "identifier.h"
	#include "functions.h"

	using namespace std;

	int yylex();
	void yyerror(const char *s);
	extern int yylineno;
	extern FILE *yyin;

	map<string, Identifier*> identifierList;


%}

%union {
	char *string;
	long long int number;
}

%token <string> DECLARE IN END
%token <string> PID
%token <number> NUM
%token <string> ASG
%token <string> IF THEN ELSE ENDIF
%token <string> WHILE DO ENDWHILE ENDDO
%token <string> FOR FROM TO DOWNTO ENDFOR
%token <string> ADD SUB MULT DIV MOD
%token <string> READ WRITE
%token <string> EQ NE LT GT LE GE
%token <string> LB RB
%token <string> SEMI COLON

%%

program:
		DECLARE declarations IN commands END
		{
			cout << "Koniec" << endl;
		}
		;

declarations:
		declarations PID SEMI
		{
			if(findIdetifier($2)) {
				string errorMessage = "Ponowna deklaracja zmiennej ";
				errorMessage.append($2);
				yyerror(errorMessage.c_str());
				exit(1);
			}
			else {
				Identifier* id = new Identifier($2, IDE);
				cout << "Name: " << id->getName() << " Typ: " << id->getType() << endl;
				identifierList.emplace($2, id);
			}
		}
		| declarations PID LB NUM COLON NUM RB SEMI
		{
			if(findIdetifier($2)) {
				string errorMessage = "Ponowna deklaracja zmiennej ";
				errorMessage.append($2);
				yyerror(errorMessage.c_str());
				exit(1);
			}
			else {
				if($4 <= $6){
					Identifier* id = new Identifier($2, ARR, $4, $6);
					cout << "Name: " << id->getName() << " Typ: " << id->getType() << " "  << id->getArrayStart() << " " << id->getArrayEnd() << endl;
					identifierList.emplace($2, id);
				}
				else {
					string errorMessage = "Niewłaściwy rozmiar tablicy ";
					errorMessage.append($2);
					yyerror(errorMessage.c_str());
					exit(1);
				}
			}
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
			cout << "Przypisanie" << endl;
		}
		| IF condition THEN commands ELSE commands ENDIF
		{
			cout << "if else" << endl;
		}
		| IF condition THEN commands ENDIF
		{
			cout << "if" << endl;
		}
		| WHILE condition DO commands ENDWHILE
		{
			cout << "while" << endl;
		}
		| DO commands WHILE condition ENDDO
		{
			cout << "do while" << endl;
		}
		| FOR PID FROM value TO value DO commands ENDFOR
		{
			cout << "from to" << endl;
		}
		| FOR PID FROM value DOWNTO value DO command ENDFOR
		{
			cout << "from downto" << endl;
		}
		| READ identifier SEMI
		{
			cout << "read" << endl;
		}
		| WRITE value SEMI
		{
			cout << "write" << endl;
		}
		;

expression:
		value
		{
			cout << "value" << endl;
		}
		| value ADD value
		{
			cout << "+" << endl;
		}
		| value SUB value
		{
			cout << "-" << endl;
		}
		| value MULT value
		{
			cout << "*" << endl;
		}
		| value DIV value
		{
			cout << "/" << endl;
		}
		| value MOD value
		{
			cout << "%" << endl;
		}
		;

condition:
		value EQ value
		{
			cout << "equals" << endl;
		}
		| value NE value
		{
			cout << "not equals" << endl;
		}
		| value LT value
		{
			cout << "less" << endl;
		}
		| value GT value
		{
			cout << "great" << endl;
		}
		| value LE value
		{
			cout << "less eq" << endl;
		}
		| value GE value
		{
			cout << "great eq" << endl;
		}
		;

value:
		NUM
		{
			cout << "Liczba" << endl;
		}
		| identifier
		{
			cout << "id" << endl;
		}
		;

identifier:
		PID
		{
			cout << "id pid" << endl;
		}
		| PID LB PID RB
		{
			cout << "id arr pid" << endl;
		}
		| PID LB NUM RB
		{
			cout << "id arr num" << endl;
		}
		;

%%

void yyerror(char const *s) {
	cerr << "Błąd w linii " << yylineno << ": " << s << endl;
	exit(1);
}

int main(int argc, char **argv) {
	yyin = fopen(argv[1], "r");
	yyparse();
	fclose(yyin);
}
