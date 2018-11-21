%{
	#define YYSTYPE std::string
	#include <iostream>
	#include <string>
	#include <cstring>
	#include <map>
	#include <vector>
	#include <fstream>
	#include "identifier.h"
	#include "array.h"
	#include "functions.h"

	#define DEBUG 0

	enum assign_type {
		IDE,
		ARR
	};

	using namespace std;
	long long int memoryIndex = 0;
	int yylex();
	void yyerror(const char *s);
	extern int yylineno;
	extern FILE *yyin;

	map<string, Identifier*> identifierList;
	map<string, Array*> arrayList;
	vector<string> commands;
	vector<string> freeRegisters{"B", "C", "D", "E", "F", "G", "H"}; // map would be better? <reg, value>

	vector<string> ident;
	Identifier* assign_id;
	pair<Array*, string> assign_arr;
	assign_type type;

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
				Identifier* id = new Identifier($2, memoryIndex);
				if(DEBUG){
					cout << "Name: " << id->getName() << " Typ: zmienna " << endl;
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
					Array* arr = new Array($2, start_arr, end_arr, memoryIndex);
					if(DEBUG){
						cout << "Name: " << arr->getName() << " Typ: Array "  << arr->getArrayStart() << " " << arr->getArrayEnd() << endl;
						cout << "Element 1: " << arr->getAssigment(9) << " " << arr->getRegister(9) << endl;
					}
					arrayList.emplace($2, arr);
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
		identifier
		{
			ident = split($1, " ");
			if(findIdetifier(ident[0])) {
				assign_id = getIdentifier(ident[0]);
				type = IDE;
			}
			else if (findArray(ident[0])) {

				if(isNumber(ident[1])){
					assign_arr = make_pair(getArray(ident[0]), ident[1]);
				}
				else if(findIdetifier(ident[1])) {
					assign_arr = make_pair(getArray(ident[0]), ident[1]);
				}
				type = ARR;
			}
		}
		ASG expression SEMI
		{
			/* if(isNumber($4)){
				string reg = assign_id->getRegister();
				if(reg.compare("None") == 0) {
					reg = freeRegisters.front();
					assign_id->setRegister(reg);
					freeRegisters.erase(freeRegisters.begin());
					freeRegisters.push_back(reg);
				}
				createNumber(stoll($4), reg);
			} */
			if(type == IDE){
				assign_id->setAssigment();
			}
			else {
				assign_arr.first->setAssigment(stoll(assign_arr.second) - assign_arr.first->getArrayStart());
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
			else {
				vector<string> write =split($2, " ");
				if (findIdetifier(write[0])) {
					Identifier* id = getIdentifier(write[0]);
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
						errorMessage.append(write[0]);
						yyerror(errorMessage.c_str());
						exit(1);
					}
				}
				else if (findArray(write[0])) {
					Array* arr_write = getArray(write[0]);
					if(isNumber(write[1])) {
						if(arr_write->getAssigment(stoll(write[1]) - arr_write->getArrayStart())) {
							string reg = arr_write->getRegister(stoll(write[1]) - arr_write->getArrayStart());
							if(reg.compare("None") == 0) {
								cout << "Tutaj jeszcze nic nie ma! (wczytanie zmiennej z pamięci)" << endl;
							}
							else {
								put(reg);
							}
						}
						else {
							string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
							errorMessage.append(write[0]);
							yyerror(errorMessage.c_str());
							exit(1);
						}
					}

				}
			}
		}
		;

expression:
		value
		{
			if(isNumber($1)){
				string reg;
				if(type == IDE){
					reg = assign_id->getRegister();
				}
				else {
					reg = assign_arr.first->getRegister(stoll(assign_arr.second) - assign_arr.first->getArrayStart());
				}
				if(reg.compare("None") == 0) {
					reg = freeRegisters.front();
					if(type == IDE){
							assign_id->setRegister(reg);
					}
					else {
						assign_arr.first->setRegister(stoll(assign_arr.second) - assign_arr.first->getArrayStart() , reg);
					}
					freeRegisters.erase(freeRegisters.begin());
					freeRegisters.push_back(reg);
				}
				createNumber(stoll($1), reg);
			}
			else if (findIdetifier($1)) {
				Identifier* id = getIdentifier($1);
				if(id->getAssigment()){
					string reg = id->getRegister();
					if(reg.compare("None") == 0) {
						cout << "Tutaj jeszcze nic nie ma! (wczytanie zmiennej z pamięci)" << endl;
					}
					else {
						string assign_reg = assign_id->getRegister();
						if(assign_reg.compare("None") == 0) {
							assign_reg = freeRegisters.front();
							assign_id->setRegister(assign_reg);
							freeRegisters.erase(freeRegisters.begin());
							freeRegisters.push_back(assign_reg);
						}
						copyreg(assign_reg, reg);
					}
				}
				else {
					string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
					errorMessage.append($1);
					yyerror(errorMessage.c_str());
					exit(1);
				}
			}
			/* else {
				pid[nr/pid]
			}
			*/
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
			if(findArray($1)) {

			}
			/* find pid*/
			cout << "id arr pid" << endl;
		}
		| PID LB NUM RB
		{
			if(findArray($1)) {
				int number = stoll($3);
				if(getArray($1)->getArrayStart() > number|| getArray($1)->getArrayEnd() < number) {
					string errorMessage = "Odwołanie do elementu spoza zakresu tablicy ";
					errorMessage.append($1);
					yyerror(errorMessage.c_str());
					exit(1);
				}
				else {
					$$ = $1 + " " + $3;
				}
			}
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
