%{
	#define YYSTYPE std::string
	#include <iostream>
	#include <string>
	#include <cstring>
	#include <map>
	#include <vector>
	#include <stack>
	#include <fstream>
	#include "identifier.h"
	#include "array.h"
	#include "functions.h"

	#define DEBUG 0



	using namespace std;
	long long int memoryIndex = 0;
	long long int step = 0;
	int yylex();
	void yyerror(const char *s);
	extern int yylineno;
	extern FILE *yyin;

	map<string, Identifier*> identifierList;
	map<string, Array*> arrayList;
	vector<string> commands;
	vector<string> registers{"B","C","D","E","F","G","H"}; // map would be better? <reg, value> nope
	stack<long long int> jumpStack;
	stack<long long int> elseStack;
	stack<long long int> loopStack;


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
			if(findIdetifier($2) || findArray($2)) {
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
			if(findIdetifier($2) || findArray($2)) {
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
					}
					arrayList.emplace($2, arr);
					memoryIndex += end_arr + 1;
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
			if (findIdetifier(ident[0])) {
				assign_id = getIdentifier(ident[0]);
				type = IDE;
			}
			else if (findArray(ident[0])) {
				assign_arr = make_pair(getArray(ident[0]), ident[1]);
				type = ARR;
			}
		}
		ASG expression SEMI
		{
			if (type == IDE) {
				assign_id->setAssigment();
			}
		}
		| IF condition THEN commands
		{
			long long int jumpPosition = jumpStack.top();
			jumpStack.pop();
			elseStack.push(step);
			jump("-1");
			fixJump(jumpPosition);
		}
		ELSE commands
		{
			long long int jump = elseStack.top();
			elseStack.pop();
			fixJump(jump);
		}
		ENDIF
		| IF condition THEN commands
		{
			long long int jump = jumpStack.top();
			jumpStack.pop();
			fixJump(jump);
		}
		ENDIF
		| WHILE
		{
			loopStack.push(step);
		}
		condition DO commands
		{
		 	long long int jumpPosition = jumpStack.top();
			jumpStack.pop();
			jump(to_string(loopStack.top()));
			loopStack.pop();
			fixJump(jumpPosition);
		}
		ENDWHILE
		| DO
		{
			loopStack.push(step);
		}
		commands WHILE condition ENDDO
		{
			long long int jumpPosition = jumpStack.top();
			jumpStack.pop();
			jump(to_string(loopStack.top()));
			loopStack.pop();
			fixJump(jumpPosition);
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
			vector<string> read = split($2, " ");
			string reg;
			if (findIdetifier(read[0])) {
				Identifier* id = getIdentifier(read[0]);
				reg = getRegID();
				createNumber(id->getMemory(), "A");
				id->setAssigment();
			}
			else if (findArray(read[0])) {
				Array* arr_write = getArray(read[0]);
				if (isNumber(read[1])) {
					reg = getRegID();
					createNumber(arr_write->getMemoryStart() + stoll(read[1]), "A");
				}
				else if (findIdetifier(read[1])) {
					Identifier* tmp = getIdentifier(read[1]);
					if (tmp->getAssigment()) {
						string tmp_reg = getRegID();
						createNumber(tmp->getMemory(), "A");
						load(tmp_reg);
						createNumber(arr_write->getMemoryStart(), "A");
						add("A", tmp_reg);
						reg = getRegID();
					}
					else {
						string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
						errorMessage.append(read[1]);
						yyerror(errorMessage.c_str());
						}
				}
			}
			get(reg);
			store(reg);
		}
		| WRITE value SEMI
		{
			if (isNumber($2)) {
				createNumber(stoll($2), "A");
				put("A");
			}
			else {
				vector<string> write = split($2, " ");
				string reg;
				if (findIdetifier(write[0])) {
					Identifier* id = getIdentifier(write[0]);
					if (id->getAssigment()) {
						reg = getRegID();
						createNumber(id->getMemory(), "A");
						load(reg);
						put(reg);
					}
					else {
						string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
						errorMessage.append(write[0]);
						yyerror(errorMessage.c_str());
						}
				}
				else if (findArray(write[0])) {
					Array* arr_write = getArray(write[0]);
					if (isNumber(write[1])) {
						createNumber(arr_write->getMemoryStart() + stoll(write[1]), "A");
						load("A");
						put("A");
					}
					else if (findIdetifier(write[1])) {
						Identifier* tmp = getIdentifier(write[1]);
						if (tmp->getAssigment()) {
							string tmp_reg = getRegID();
							createNumber(tmp->getMemory(), "A");
							load(tmp_reg);
							createNumber(arr_write->getMemoryStart(), "A");
							add("A", tmp_reg);
							load("A");
							put("A");
						}
						else {
							string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
							errorMessage.append(write[1]);
							yyerror(errorMessage.c_str());
						}
					}
				}
			}
		}
		;

expression:
		value
		 {
			string reg;
			if (isNumber($1)) {
				reg = getRegID();
				createNumber(stoll($1), reg);
			}
			else {
				vector<string> pid_value = split($1, " ");
				if (findIdetifier(pid_value[0])) {
					Identifier* id = getIdentifier(pid_value[0]);
					if (id->getAssigment()) {
						reg = getRegID();
						createNumber(id->getMemory(), "A");
						load(reg);
					}
					else {
						string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
						errorMessage.append(pid_value[0]);
						yyerror(errorMessage.c_str());
					}
				}
				else if (findArray(pid_value[0])) {
					Array* arr = getArray(pid_value[0]);
					if (isNumber(pid_value[1])) {
						reg = getRegID();
						createNumber(arr->getMemoryStart() + stoll(pid_value[1]) , "A");
						load(reg);
					}
					else if (findIdetifier(pid_value[1])) {
						Identifier* tmp = getIdentifier(pid_value[1]);
						if (tmp->getAssigment()) {
							string tmp_reg = getRegID();
							createNumber(tmp->getMemory(), "A");
							load(tmp_reg);
							reg = getRegID();
							createNumber(arr->getMemoryStart(), "A");
							add("A", tmp_reg);
							load(reg);
						}
						else {
							string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
							errorMessage.append(pid_value[1]);
							yyerror(errorMessage.c_str());
						}
					}
				}
			}
			if (type == ARR) {
				storeArrayAssign(reg);
			}
			else if (type == IDE) {
				storeIdeAssign(reg);
			}
		}
		| value ADD value
		{
			string reg_a;
			string reg_b;
			tie(reg_a, reg_b) = loadValuesToRegister($1,$3);
			add(reg_a, reg_b);
			if (type == IDE){
				storeIdeAssign(reg_a);
			}
			else if (type == ARR) {
				storeArrayAssign(reg_a);
			}
		}
		| value SUB value
		{
			string reg_a;
			string reg_b;
			tie(reg_a, reg_b) = loadValuesToRegister($1,$3);
			sub(reg_a, reg_b);
			if (type == IDE){
				storeIdeAssign(reg_a);
			}
			else if (type == ARR) {
				storeArrayAssign(reg_a);
			}
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
			string reg_a;
			string reg_b;
			string reg_comp_a;
			string reg_comp_b;
			tie(reg_a, reg_b) = loadValuesToRegister($1,$3);
			reg_comp_a = getRegID();
			reg_comp_b = getRegID();
			copyreg(reg_comp_a, reg_a);
			copyreg(reg_comp_b, reg_b);
			sub(reg_comp_a, reg_b);
			sub(reg_comp_b, reg_a);
			add(reg_comp_a, reg_comp_b);
			jzero(reg_comp_a, to_string(step + 2));
			jumpStack.push(step);
			jump("-1");
		}
		| value NE value
		{
			string reg_a;
			string reg_b;
			string reg_comp_a;
			string reg_comp_b;
			tie(reg_a, reg_b) = loadValuesToRegister($1,$3);
			reg_comp_a = getRegID();
			reg_comp_b = getRegID();
			copyreg(reg_comp_a, reg_a);
			copyreg(reg_comp_b, reg_b);
			sub(reg_comp_a, reg_b);
			sub(reg_comp_b, reg_a);
			add(reg_comp_a, reg_comp_b);
			jumpStack.push(step);
			jzero(reg_comp_a, to_string(-1));
		}
		| value LT value
		{
			string reg_a;
			string reg_b;
			string reg_comp_a;
			string reg_comp_b;
			tie(reg_a, reg_b) = loadValuesToRegister($1,$3);
			sub(reg_b, reg_a);
			jumpStack.push(step);
			jzero(reg_b, to_string(-1));
		}
		| value GT value
		{
			string reg_a;
			string reg_b;
			string reg_comp_a;
			string reg_comp_b;
			tie(reg_a, reg_b) = loadValuesToRegister($1,$3);
			inc(reg_b);
			sub(reg_b, reg_a);
			jzero(reg_comp_a, to_string(step + 2));
			jumpStack.push(step);
			jump("-1");
		}
		| value LE value
		{
			string reg_a;
			string reg_b;
			string reg_comp_a;
			string reg_comp_b;
			tie(reg_a, reg_b) = loadValuesToRegister($1,$3);
			inc(reg_b);
			sub(reg_b, reg_a);
			jumpStack.push(step);
			jzero(reg_b, to_string(-1));
		}
		| value GE value
		{
			string reg_a;
			string reg_b;
			string reg_comp_a;
			string reg_comp_b;
			tie(reg_a, reg_b) = loadValuesToRegister($1,$3);
			sub(reg_b, reg_a);
			jzero(reg_comp_a, to_string(step + 2));
			jumpStack.push(step);
			jump("-1");
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
			if (findIdetifier($1)) {
				$$=$1;
			}
			else {
				string errorMessage;
				if (findArray($1)) {
					errorMessage = "Niewłaściwe odwołanie do tablicy ";
				}
				else {
					errorMessage = "Odwołanie do niezadeklarowanej zmiennej ";
				}
				errorMessage.append($1);
				yyerror(errorMessage.c_str());
				exit(1);
			}
		}
		| PID LB PID RB
		{
			if (findArray($1)) {
				if (findIdetifier($3)) {
					if (getIdentifier($3)->getAssigment()) {
						$$ = $1 + " " + $3;
					}
					else {
						string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
						errorMessage.append($3);
						yyerror(errorMessage.c_str());
						exit(1);
					}
				}
				else {
					string errorMessage = "Odwołanie do niezadeklarowanej zmiennej ";
					errorMessage.append($3);
					yyerror(errorMessage.c_str());
					exit(1);
				}
			}
			else {
				string errorMessage;
				if(findIdetifier($1)){
					errorMessage = "Niewłaściwe odwołanie do zmiennej ";
				}
				else {
					errorMessage = "Odwołanie do niezadeklarowanej tablicy ";
				}
				errorMessage.append($1);
				yyerror(errorMessage.c_str());
				exit(1);
			}
		}
		| PID LB NUM RB
		{
			if (findArray($1)) {
				int number = stoll($3);
				if (getArray($1)->getArrayStart() > number|| getArray($1)->getArrayEnd() < number) {
					string errorMessage = "Odwołanie do elementu spoza zakresu tablicy ";
					errorMessage.append($1);
					yyerror(errorMessage.c_str());
					exit(1);
				}
				else {
					$$ = $1 + " " + $3;
				}
			}
			else {
				string errorMessage;
				if (findIdetifier($1)) {
					errorMessage = "Niewłaściwe odwołanie do zmiennej ";
				}
				else {
					errorMessage = "Odwołanie do niezadeklarowanej tablicy ";
				}
				errorMessage.append($1);
				yyerror(errorMessage.c_str());
				exit(1);
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
	for (long long int i = 0; i < commands.size(); i++) {
		out << commands[i] << endl;
	}
	cout << endl;
	out.close();

}
