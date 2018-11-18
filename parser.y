%{
	#define YYSTYPE std::string
	#include <iostream>
	#include <string>
	#include <cstring>
	#include <map>
	#include <vector>
	#include <fstream>
	#include "identifier.h"
	#include "functions.h"

	#define DEBUG 0

	using namespace std;
	long long int memoryIndex = 0;
	int yylex();
	void yyerror(const char *s);
	extern int yylineno;
	extern FILE *yyin;

	map<string, Identifier*> identifierList;
	vector<string> commands;
	vector<string> freeRegisters{"B", "C", "D", "E", "F", "G", "H"};


%}


%token DECLARE IN END
%token PID
%token NUM
%token ASG
%token IF THEN ELSE ENDIF
%token WHILE DO ENDWHILE ENDDO
%token FOR FROM TO DOWNTO ENDFOR
%token ADD SUB MULT DIV MOD
%token READ WRITE
%token EQ NE LT GT LE GE
%token LB RB
%token SEMI COLON


%%

program:
		DECLARE declarations IN commands END
		{
			if(DEBUG){
				cout << "Koniec" << endl;
			}
			halt();
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
				Identifier* id = new Identifier($2, IDE, memoryIndex);
				if(DEBUG){
					cout << "Name: " << id->getName() << " Typ: " << id->getType() << endl;
				}
				identifierList.emplace($2, id);
				memoryIndex++;
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
				long long int start_arr = stoll($4);
				long long int end_arr = stoll($6);
				if(start_arr <= end_arr){
					Identifier* id = new Identifier($2, ARR, start_arr, end_arr, memoryIndex);
					if(DEBUG){
						cout << "Name: " << id->getName() << " Typ: " << id->getType() << " "  << id->getArrayStart() << " " << id->getArrayEnd() << endl;
					}
					identifierList.emplace($2, id);
					memoryIndex += end_arr - start_arr + 1;
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
			Identifier* id = getIdentifier($1);
			id->setAssigment();
			if(isNumber($3)){
				string reg = id->getRegister();
				if(reg.compare("None") == 0) {
					reg = freeRegisters.front();
					id->setRegister(reg);
					freeRegisters.erase(freeRegisters.begin());
					freeRegisters.push_back(reg);
				}
				createNumber(stoll($3), reg);
			}

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
			if(findIdetifier($1)) {
				Identifier* read = getIdentifier($1);
			}
		}
		| WRITE value SEMI
		{
			if(isNumber($2)){
				string reg = freeRegisters.front();
				freeRegisters.erase(freeRegisters.begin());
				freeRegisters.push_back(reg);
				createNumber(stoll($2), reg);
				put(reg);
			}
			else if (findIdetifier($2)) {
				Identifier* id = getIdentifier($2);
				if(id->getAssigment()){
					string reg = id->getRegister();
					if(reg.compare("None") == 0) {
						cout << "Tutaj jeszcze nic nie ma! (wczytanie zmiennej z pamięci)" << endl;
					}
					else {
						put(reg);
					}
				}
				else {
					string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
					errorMessage.append($2);
					yyerror(errorMessage.c_str());
					exit(1);
				}
			}

		}
		;

expression:
		value
		{
			$$=$1;

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

		}
		| identifier
		{
			$$=$1;
		}
		;

identifier:
		PID
		{
			if(findIdetifier($1)) {
				$$=$1;
			}
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
	wypisz();
	ofstream out;
	out.open(argv[2]);
	for(long long int i = 0; i < commands.size(); i++) {
		out << commands[i] << endl;
	}
	out.close();

}
