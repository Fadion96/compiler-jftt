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
					cout << "Name: " << id->getName() << " Iterator: " << id->getIterator() << endl;
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
				if(assign_id->getIterator()) {
					string errorMessage = "Próba zmiany wartości iteratora: ";
					errorMessage.append(ident[0]);
					yyerror(errorMessage.c_str());
				}
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
		ELSE commands ENDIF
		{
			long long int jump = elseStack.top();
			elseStack.pop();
			fixJump(jump);
		}
		| IF condition THEN commands ENDIF
		{
			long long int jump = jumpStack.top();
			jumpStack.pop();
			fixJump(jump);
		}
		| WHILE
		{
			loopStack.push(step);
		}
		condition DO commands ENDWHILE
		{
		 	long long int jumpPosition = jumpStack.top();
			jumpStack.pop();
			jump(to_string(loopStack.top()));
			loopStack.pop();
			fixJump(jumpPosition);
		}
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
		| FOR PID FROM value TO value
		{
			Identifier* id;
			if (findIdetifier($2) || findArray($2)) {
				string errorMessage = "Ponowna deklaracja zmiennej ";
				errorMessage.append($2);
				yyerror(errorMessage.c_str());
				exit(1);
			}
			else {
				id = new Identifier($2, memoryIndex, true);
				if(DEBUG){
					cout << "Name: " << id->getName() << " Iterator: "  << id->getIterator() << endl;
				}
				identifierList.emplace($2, id);
				memoryIndex++;
			}
			Identifier* first_temp_value = new Identifier("TEMP" + $4, memoryIndex);
			memoryIndex++;
			if(DEBUG){
				cout << "Name: " << first_temp_value->getName() << " Iterator: "  << first_temp_value->getIterator() << endl;
			}
			Identifier* second_temp_value = new Identifier("TEMP" + $6, memoryIndex);
			memoryIndex++;
			if(DEBUG){
				cout << "Name: " << second_temp_value->getName() << " Iterator: "  << second_temp_value->getIterator() << endl;
			}
			if (isNumber($4)) {
				string reg = getRegID();
				createNumber(stoll($4), reg);
				createNumber(first_temp_value->getMemory(), "A");
				store(reg);
			}
			else {
				vector<string> first_value = split($4, " ");
				if (findIdetifier(first_value[0])) {
					Identifier* tmp_id = getIdentifier(first_value[0]);
					if (tmp_id->getAssigment()) {
						string reg = getRegID();
						createNumber(tmp_id->getMemory(), "A");
						load(reg);
						createNumber(first_temp_value->getMemory(), "A");
						store(reg);
					}
					else {
						string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
						errorMessage.append(first_value[0]);
						yyerror(errorMessage.c_str());
					}
				}
				else if (findArray(first_value[0])) {
					Array* tmp_arr = getArray(first_value[0]);
					if (isNumber(first_value[1])) {
						string reg = getRegID();
						createNumber(tmp_arr->getMemoryStart() + stoll(first_value[1]) , "A");
						load(reg);
						createNumber(first_temp_value->getMemory(), "A");
						store(reg);
					}
					else if (findIdetifier(first_value[1])) {
						Identifier* tmp = getIdentifier(first_value[1]);
						if (tmp->getAssigment()) {
							string tmp_reg = getRegID();
							createNumber(tmp->getMemory(), "A");
							load(tmp_reg);
							string reg = getRegID();
							createNumber(tmp_arr->getMemoryStart(), "A");
							add("A", tmp_reg);
							load(reg);
							createNumber(first_temp_value->getMemory(), "A");
							store(reg);
						}
						else {
							string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
							errorMessage.append(first_value[1]);
							yyerror(errorMessage.c_str());
						}
					}
				}
			}
			if (isNumber($6)) {
				string reg = getRegID();
				createNumber(stoll($6), reg);
				createNumber(second_temp_value->getMemory(), "A");
				store(reg);
			}
			else {
				vector<string> second_value = split($6, " ");
				if (findIdetifier(second_value[0])) {
					Identifier* tmp_id = getIdentifier(second_value[0]);
					if (tmp_id->getAssigment()) {
						string reg = getRegID();
						createNumber(tmp_id->getMemory(), "A");
						load(reg);
						createNumber(second_temp_value->getMemory(), "A");
						store(reg);
					}
					else {
						string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
						errorMessage.append(second_value[0]);
						yyerror(errorMessage.c_str());
					}
				}
				else if (findArray(second_value[0])) {
					Array* tmp_arr = getArray(second_value[0]);
					if (isNumber(second_value[1])) {
						string reg = getRegID();
						createNumber(tmp_arr->getMemoryStart() + stoll(second_value[1]) , "A");
						load(reg);
						createNumber(second_temp_value->getMemory(), "A");
						store(reg);
					}
					else if (findIdetifier(second_value[1])) {
						Identifier* tmp = getIdentifier(second_value[1]);
						if (tmp->getAssigment()) {
							string tmp_reg = getRegID();
							createNumber(tmp->getMemory(), "A");
							load(tmp_reg);
							string reg = getRegID();
							createNumber(tmp_arr->getMemoryStart(), "A");
							add("A", tmp_reg);
							load(reg);
							createNumber(second_temp_value->getMemory(), "A");
							store(reg);
						}
						else {
							string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
							errorMessage.append(second_value[1]);
							yyerror(errorMessage.c_str());
						}
					}
				}
			}
			string from_value_reg = getRegID();
			string iterator_reg = getRegID();
			string to_value_reg = getRegID();
			createNumber(first_temp_value->getMemory(), "A");
			load(from_value_reg);
			copyreg(iterator_reg, from_value_reg);
			id->setAssigment();
			createNumber(id->getMemory(), "A");
			store(iterator_reg);
			loopStack.push(step);
			createNumber(id->getMemory(), "A");
			load(iterator_reg);
			createNumber(second_temp_value->getMemory(), "A");
			load(to_value_reg);
			inc(to_value_reg);
			sub(to_value_reg, iterator_reg);
			jumpStack.push(step);
			jzero(to_value_reg, to_string(-1));
		}
		DO commands ENDFOR
		{
			string iterator_reg = getRegID();
			createNumber(getIdentifier($2)->getMemory(), "A");
			load(iterator_reg);
			inc(iterator_reg);
			store(iterator_reg);
			long long int jumpPosition = jumpStack.top();
			jumpStack.pop();
			jump(to_string(loopStack.top()));
			loopStack.pop();
			fixJump(jumpPosition);
			identifierList.erase($2);
		}
		| FOR PID FROM value DOWNTO value
		{
			Identifier* id;
			if (findIdetifier($2) || findArray($2)) {
				string errorMessage = "Ponowna deklaracja zmiennej ";
				errorMessage.append($2);
				yyerror(errorMessage.c_str());
				exit(1);
			}
			else {
				id = new Identifier($2, memoryIndex, true);
				if(DEBUG){
					cout << "Name: " << id->getName() << " Iterator: "  << id->getIterator() << endl;
				}
				identifierList.emplace($2, id);
				memoryIndex++;
			}
			Identifier* first_temp_value = new Identifier("TEMP" + $4, memoryIndex);
			if(DEBUG){
				cout << "Name: " << first_temp_value->getName() << " Iterator: "  << first_temp_value->getIterator() << endl;
			}
			memoryIndex++;
			Identifier* second_temp_value = new Identifier("TEMP" + $6, memoryIndex);
			memoryIndex++;
			if(DEBUG){
				cout << "Name: " << second_temp_value->getName() << " Iterator: "  << second_temp_value->getIterator() << endl;
			}
			if (isNumber($4)) {
				string reg = getRegID();
				createNumber(stoll($4), reg);
				createNumber(first_temp_value->getMemory(), "A");
				store(reg);
			}
			else {
				vector<string> first_value = split($4, " ");
				if (findIdetifier(first_value[0])) {
					Identifier* tmp_id = getIdentifier(first_value[0]);
					if (tmp_id->getAssigment()) {
						string reg = getRegID();
						createNumber(tmp_id->getMemory(), "A");
						load(reg);
						createNumber(first_temp_value->getMemory(), "A");
						store(reg);
					}
					else {
						string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
						errorMessage.append(first_value[0]);
						yyerror(errorMessage.c_str());
					}
				}
				else if (findArray(first_value[0])) {
					Array* tmp_arr = getArray(first_value[0]);
					if (isNumber(first_value[1])) {
						string reg = getRegID();
						createNumber(tmp_arr->getMemoryStart() + stoll(first_value[1]) , "A");
						load(reg);
						createNumber(first_temp_value->getMemory(), "A");
						store(reg);
					}
					else if (findIdetifier(first_value[1])) {
						Identifier* tmp = getIdentifier(first_value[1]);
						if (tmp->getAssigment()) {
							string tmp_reg = getRegID();
							createNumber(tmp->getMemory(), "A");
							load(tmp_reg);
							string reg = getRegID();
							createNumber(tmp_arr->getMemoryStart(), "A");
							add("A", tmp_reg);
							load(reg);
							createNumber(first_temp_value->getMemory(), "A");
							store(reg);
						}
						else {
							string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
							errorMessage.append(first_value[1]);
							yyerror(errorMessage.c_str());
						}
					}
				}
			}
			if (isNumber($6)) {
				string reg = getRegID();
				createNumber(stoll($6), reg);
				createNumber(second_temp_value->getMemory(), "A");
				store(reg);
			}
			else {
				vector<string> second_value = split($6, " ");
				if (findIdetifier(second_value[0])) {
					Identifier* tmp_id = getIdentifier(second_value[0]);
					if (tmp_id->getAssigment()) {
						string reg = getRegID();
						createNumber(tmp_id->getMemory(), "A");
						load(reg);
						createNumber(second_temp_value->getMemory(), "A");
						store(reg);
					}
					else {
						string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
						errorMessage.append(second_value[0]);
						yyerror(errorMessage.c_str());
					}
				}
				else if (findArray(second_value[0])) {
					Array* tmp_arr = getArray(second_value[0]);
					if (isNumber(second_value[1])) {
						string reg = getRegID();
						createNumber(tmp_arr->getMemoryStart() + stoll(second_value[1]) , "A");
						load(reg);
						createNumber(second_temp_value->getMemory(), "A");
						store(reg);
					}
					else if (findIdetifier(second_value[1])) {
						Identifier* tmp = getIdentifier(second_value[1]);
						if (tmp->getAssigment()) {
							string tmp_reg = getRegID();
							createNumber(tmp->getMemory(), "A");
							load(tmp_reg);
							string reg = getRegID();
							createNumber(tmp_arr->getMemoryStart(), "A");
							add("A", tmp_reg);
							load(reg);
							createNumber(second_temp_value->getMemory(), "A");
							store(reg);
						}
						else {
							string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
							errorMessage.append(second_value[1]);
							yyerror(errorMessage.c_str());
						}
					}
				}
			}
			string from_value_reg = getRegID();
			string iterator_reg = getRegID();
			string to_value_reg = getRegID();
			createNumber(first_temp_value->getMemory(), "A");
			load(from_value_reg);
			copyreg(iterator_reg, from_value_reg);
			id->setAssigment();
			createNumber(id->getMemory(), "A");
			store(iterator_reg);
			loopStack.push(step);
			createNumber(id->getMemory(), "A");
			load(iterator_reg);
			createNumber(second_temp_value->getMemory(), "A");
			load(to_value_reg);
			inc(iterator_reg);
			sub(iterator_reg, to_value_reg);
			jumpStack.push(step);
			jzero(iterator_reg, to_string(-1));

		}
		DO command ENDFOR
		{
			string iterator_reg = getRegID();
			createNumber(getIdentifier($2)->getMemory(), "A");
			load(iterator_reg);
			jzero(iterator_reg, to_string(step + 4));
			dec(iterator_reg);
			store(iterator_reg);
			long long int jumpPosition = jumpStack.top();
			jumpStack.pop();
			jump(to_string(loopStack.top()));
			loopStack.pop();
			fixJump(jumpPosition);
			identifierList.erase($2);
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
			string reg_a;
			string reg_b;
			tie(reg_a, reg_b) = loadValuesToRegister($1,$3);
			string mult = getRegID();
			string tmp = getRegID();
			string tmp_a = getRegID();
			string tmp_b = getRegID();
			sub(mult, mult);
			sub(tmp_a,tmp_a);
			copyreg(tmp_b, reg_a);
			sub(tmp_b, reg_b);
			jzero(tmp_b, to_string(step + 11));
			copyreg(tmp, reg_a);
			copyreg(tmp_b, reg_b);
			sub(tmp_b, tmp_a);
			jzero(tmp_b, to_string(step + 17));
			inc(tmp_b);
			jodd(tmp_b, to_string(step + 2));
			add(mult, tmp);
			half(reg_b);
			add(tmp,tmp);
			jump(to_string(step - 8));
			copyreg(tmp, reg_b);
			copyreg(tmp_b, reg_a);
			sub(tmp_b, tmp_a);
			jzero(tmp_b, to_string(step + 7));
			inc(tmp_b);
			jodd(tmp_b, to_string(step + 2));
			add(mult, tmp);
			half(reg_a);
			add(tmp, tmp);
			jump(to_string(step - 8));
			if (type == IDE){
				storeIdeAssign(mult);
			}
			else if (type == ARR) {
				storeArrayAssign(mult);
			}
		}
		| value DIV value
		{
			string reg_a;
			string reg_b;
			tie(reg_a, reg_b) = loadValuesToRegister($1,$3);
			string divi = getRegID();
			string tmp = getRegID();
			string tmp_b = getRegID();
			sub(divi, divi);
			sub(tmp, tmp);
			jzero(reg_a, to_string(step + 20));
			jzero(reg_b, to_string(step + 19));
			copyreg(tmp_b, reg_b);
			sub(tmp_b, reg_a);
			jzero(tmp_b, to_string(step + 2));
			jump(to_string(step + 4));
			add(reg_b, reg_b);
			inc(tmp);
			jump(to_string(step - 7));
			jzero(tmp, to_string(step + 11));
			dec(tmp);
			half(reg_b);
			add(divi, divi);
			copyreg(tmp_b, reg_b);
			sub(tmp_b, reg_a);
			jzero(tmp_b, to_string(step + 2));
			jump(to_string(step + 3));
			sub(reg_a, reg_b);
			inc(divi);
			jump(to_string(step - 10));
			if (type == IDE){
				storeIdeAssign(divi);
			}
			else if (type == ARR) {
				storeArrayAssign(divi);
			}
		}
		| value MOD value
		{
			string reg_a;
			string reg_b;
			tie(reg_a, reg_b) = loadValuesToRegister($1,$3);
			string divi = getRegID();
			string tmp = getRegID();
			string tmp_b = getRegID();
			sub(divi, divi);
			sub(tmp, tmp);
			jzero(reg_a, to_string(step + 21));
			jzero(reg_b, to_string(step + 19));
			copyreg(tmp_b, reg_b);
			sub(tmp_b, reg_a);
			jzero(tmp_b, to_string(step + 2));
			jump(to_string(step + 4));
			add(reg_b, reg_b);
			inc(tmp);
			jump(to_string(step - 7));
			jzero(tmp, to_string(step + 12));
			dec(tmp);
			half(reg_b);
			add(divi, divi);
			copyreg(tmp_b, reg_b);
			sub(tmp_b, reg_a);
			jzero(tmp_b, to_string(step + 2));
			jump(to_string(step + 3));
			sub(reg_a, reg_b);
			inc(divi);
			jump(to_string(step - 10));
			copyreg(reg_a, reg_b);
			if (type == IDE){
				storeIdeAssign(reg_a);
			}
			else if (type == ARR) {
				storeArrayAssign(reg_a);
			}
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
			tie(reg_a, reg_b) = loadValuesToRegister($1,$3);
			sub(reg_b, reg_a);
			jumpStack.push(step);
			jzero(reg_b, to_string(-1));
		}
		| value GT value
		{
			string reg_a;
			string reg_b;
			tie(reg_a, reg_b) = loadValuesToRegister($1,$3);
			sub(reg_a, reg_b);
			jumpStack.push(step);
			jzero(reg_a, to_string(-1));
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
			tie(reg_a, reg_b) = loadValuesToRegister($1,$3);
			inc(reg_a);
			sub(reg_a, reg_b);
			jumpStack.push(step);
			jzero(reg_a, to_string(-1));
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
	if (!DEBUG) {
		ofstream out;
		out.open(argv[2]);
		for (long long int i = 0; i < commands.size(); i++) {
			out << commands[i] << endl;
		}
		out.close();
	}

}
