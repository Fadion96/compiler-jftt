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
	vector<pair<string, string>> registers{{"B", "None"}, {"C", "None"}, {"D", "None"}, {"E", "None"}, {"F", "None"}, {"G", "None"}, {"H", "None"}}; // map would be better? <reg, value>

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
			vector<string> read = split($2, " ");
			if (findIdetifier(read[0])) {
				Identifier* id = getIdentifier(read[0]);
				string reg = id->getRegister();
				if(reg.compare("None") == 0) {
					reg = getRegID();
					id->setRegister(reg);
					registers.erase(registers.begin());
					registers.push_back(make_pair(reg,id->getName()));
				}
				get(reg);
				id->setAssigment();
			}
			else if (findArray(read[0])) {
				Array* arr_write = getArray(read[0]);
				if (isNumber(read[1])) {
					createNumber(arr_write->getMemoryStart() + stoll(read[1]), "A");
					string tmp_reg = getRegID();
					registers.erase(registers.begin());
					registers.push_back(make_pair(tmp_reg, "None"));
					get(tmp_reg);
					store(tmp_reg);
				}
				else if (findIdetifier(read[1])) {
					Identifier* tmp = getIdentifier(read[1]);
					if (tmp->getAssigment()) {
						string tmp_reg = tmp->getRegister();
						if (tmp_reg.compare("None") == 0) {
							tmp_reg = getRegID();
							registers.erase(registers.begin());
							registers.push_back(make_pair(tmp_reg, read[1]));
							tmp->setRegister(tmp_reg);
							createNumber(tmp->getMemory(), "A");
							load(tmp_reg);
						}
						createNumber(arr_write->getMemoryStart(), "A");
						add("A", tmp_reg);
						string read_reg = getRegID();
						registers.erase(registers.begin());
						registers.push_back(make_pair(tmp_reg, "None"));
						get(read_reg);
						store(read_reg);
					}
					else {
						string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
						errorMessage.append(read[1]);
						yyerror(errorMessage.c_str());
						exit(1);
					}
				}
			}
		}
		| WRITE value SEMI
		{
			if (isNumber($2)) {
				createNumber(stoll($2), "A");
				put("A");
			}
			else {
				vector<string> write = split($2, " ");
				if (findIdetifier(write[0])) {
					Identifier* id = getIdentifier(write[0]);
					if (id->getAssigment()) {
						string reg = id->getRegister();
						if(reg.compare("None") == 0) {
							reg = getRegID();
							createNumber(id->getMemory(), "A");
							load(reg);
							id->setRegister(reg);
							registers.erase(registers.begin());
							registers.push_back(make_pair(reg,id->getName()));
						}
						put(reg);
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
					if (isNumber(write[1])) {
						createNumber(arr_write->getMemoryStart() + stoll(write[1]), "A");
						load("A");
						put("A");
					}
					else if (findIdetifier(write[1])) {
						Identifier* tmp = getIdentifier(write[1]);
						if (tmp->getAssigment()) {
							string tmp_reg = tmp->getRegister();
							if (tmp_reg.compare("None") == 0) {
								tmp_reg = getRegID();
								registers.erase(registers.begin());
								registers.push_back(make_pair(tmp_reg, write[1]));
								tmp->setRegister(tmp_reg);
								createNumber(tmp->getMemory(), "A");
								load(tmp_reg);
							}
							createNumber(arr_write->getMemoryStart(), "A");
							add("A", tmp_reg);
							load("A");
							put("A");
						}
						else {
							string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
							errorMessage.append(write[1]);
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
			if (isNumber($1)) {
				string reg = "None";
				if (type == IDE) {
					reg = assign_id->getRegister();
				}
				if (reg.compare("None") == 0) {
					reg = getRegID();
					if (type == IDE) {
						assign_id->setRegister(reg);
						registers.erase(registers.begin());
						registers.push_back(make_pair(reg, assign_id->getName()));
					}
					else {
						registers.erase(registers.begin());
						registers.push_back(make_pair(reg, "None"));
					}
				}
				createNumber(stoll($1), reg);
				if (type == ARR) {
					if (isNumber(assign_arr.second)) {
						createNumber(assign_arr.first->getMemoryStart() + stoll(assign_arr.second), "A");
						store(reg);
					}
					else if (findIdetifier(assign_arr.second)) {
						Identifier* tmp = getIdentifier(assign_arr.second);
						if (tmp->getAssigment()) {
							string tmp_reg = tmp->getRegister();
							if (tmp_reg.compare("None") == 0) {
								tmp_reg = getRegID();
								registers.erase(registers.begin());
								registers.push_back(make_pair(tmp_reg, assign_arr.second));
								tmp->setRegister(tmp_reg);
								createNumber(tmp->getMemory(), "A");
								load(tmp_reg);
							}
							createNumber(assign_arr.first->getMemoryStart(), "A");
							add("A", tmp_reg);
							store(reg);
						}
						else {
							string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
							errorMessage.append(assign_arr.second);
							yyerror(errorMessage.c_str());
							exit(1);
						}
					}
				}
			}
			else {
				vector<string> pid_value = split($1, " ");
				if (findIdetifier(pid_value[0])) {
					Identifier* id = getIdentifier(pid_value[0]);
					if (id->getAssigment()) {
						string reg = id->getRegister();
						if (reg.compare("None") == 0) {
							reg = getRegID();
							createNumber(id->getMemory(), "A");
							load(reg);
							id->setRegister(reg);
							registers.erase(registers.begin());
							registers.push_back(make_pair(reg,id->getName()));
						}
						string assign_reg = "None";
						if (type == IDE) {
							assign_reg = assign_id->getRegister();
						}
						if (assign_reg.compare("None") == 0) {
							assign_reg = getRegID();
							if (type == IDE) {
								assign_id->setRegister(assign_reg);
								registers.erase(registers.begin());
								registers.push_back(make_pair(assign_reg, assign_id->getName()));
							}
							else {
								registers.erase(registers.begin());
								registers.push_back(make_pair(reg, "None"));
							}
						}
						copyreg(assign_reg, reg);
						if (type == ARR) {
							if (isNumber(assign_arr.second)) {
								createNumber(assign_arr.first->getMemoryStart() + stoll(assign_arr.second), "A");
								store(assign_reg);
							}
							else if (findIdetifier(assign_arr.second)) {
								Identifier* tmp = getIdentifier(assign_arr.second);
								if (tmp->getAssigment()) {
									string tmp_reg = tmp->getRegister();
									if (tmp_reg.compare("None") == 0) {
										tmp_reg = getRegID();
										registers.erase(registers.begin());
										registers.push_back(make_pair(tmp_reg, assign_arr.second));
										tmp->setRegister(tmp_reg);
										createNumber(tmp->getMemory(), "A");
										load(tmp_reg);
									}
									createNumber(assign_arr.first->getMemoryStart(), "A");
									add("A", tmp_reg);
									store(reg);
								}
								else {
									string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
									errorMessage.append(assign_arr.second);
									yyerror(errorMessage.c_str());
									exit(1);
								}
							}
						}
					}
					else {
						string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
						errorMessage.append(pid_value[0]);
						yyerror(errorMessage.c_str());
						exit(1);
					}
				}
				else if (findArray(pid_value[0])) {
					Array* arr = getArray(pid_value[0]);
					if (isNumber(pid_value[1])) {
						string reg = getRegID();
						createNumber(arr->getMemoryStart() + stoll(pid_value[1]) , "A");
						load(reg);
						registers.erase(registers.begin());
						registers.push_back(make_pair(reg, "None"));
						string assign_reg = "None";
						if (type == IDE) {
							assign_reg = assign_id->getRegister();
						}
						if (assign_reg.compare("None") == 0) {
							assign_reg = getRegID();
							if (type == IDE) {
								assign_id->setRegister(assign_reg);
								registers.erase(registers.begin());
								registers.push_back(make_pair(assign_reg, assign_id->getName()));
							}
							else {
								registers.erase(registers.begin());
								registers.push_back(make_pair(reg, "None"));
							}
						}
						copyreg(assign_reg, reg);
						if (type == ARR) {
							if (isNumber(assign_arr.second)) {
								createNumber(assign_arr.first->getMemoryStart() + stoll(assign_arr.second), "A");
								store(assign_reg);
							}
							else if (findIdetifier(assign_arr.second)) {
								Identifier* tmp = getIdentifier(assign_arr.second);
								if (tmp->getAssigment()) {
									string tmp_reg = tmp->getRegister();
									if (tmp_reg.compare("None") == 0) {
										tmp_reg = getRegID();
										registers.erase(registers.begin());
										registers.push_back(make_pair(tmp_reg, assign_arr.second));
										tmp->setRegister(tmp_reg);
										createNumber(tmp->getMemory(), "A");
										load(tmp_reg);
									}
									createNumber(assign_arr.first->getMemoryStart(), "A");
									add("A", tmp_reg);
									store(reg);
								}
								else {
									string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
									errorMessage.append(assign_arr.second);
									yyerror(errorMessage.c_str());
									exit(1);
								}
							}
						}
					}
					else if (findIdetifier(pid_value[1])) {
						string reg;
						Identifier* tmp = getIdentifier(pid_value[1]);
						if (tmp->getAssigment()) {
							string tmp_reg = tmp->getRegister();
							if (tmp_reg.compare("None") == 0) {
								tmp_reg = getRegID();
								registers.erase(registers.begin());
								registers.push_back(make_pair(tmp_reg, pid_value[1]));
								tmp->setRegister(tmp_reg);
								createNumber(tmp->getMemory(), "A");
								load(tmp_reg);
							}
							reg = getRegID();
							createNumber(arr->getMemoryStart(), "A");
							add("A", tmp_reg);
							load(reg);
							string assign_reg = "None";
							if (type == IDE) {
								assign_reg = assign_id->getRegister();
							}
							if (assign_reg.compare("None") == 0) {
								assign_reg = reg;
								if (type == IDE) {
									assign_id->setRegister(reg);
									registers.erase(registers.begin());
									registers.push_back(make_pair(reg, assign_id->getName()));
								}
								else {
									registers.erase(registers.begin());
									registers.push_back(make_pair(reg, "None"));
								}
							}
							else {
								copyreg(assign_reg, reg);
							}
							if (type == ARR) {
								if (isNumber(assign_arr.second)) {
									createNumber(assign_arr.first->getMemoryStart() + stoll(assign_arr.second), "A");
									store(assign_reg);
								}
								else if (findIdetifier(assign_arr.second)) {
									Identifier* tmp = getIdentifier(assign_arr.second);
									if (tmp->getAssigment()) {
										string tmp_reg = tmp->getRegister();
										if (tmp_reg.compare("None") == 0) {
											tmp_reg = getRegID();
											registers.erase(registers.begin());
											registers.push_back(make_pair(tmp_reg, assign_arr.second));
											tmp->setRegister(tmp_reg);
											createNumber(tmp->getMemory(), "A");
											load(tmp_reg);
										}
										createNumber(assign_arr.first->getMemoryStart(), "A");
										add("A", tmp_reg);
										store(reg);
									}
									else {
										string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
										errorMessage.append(assign_arr.second);
										yyerror(errorMessage.c_str());
										exit(1);
									}
								}
							}
						}
					}
				}
			}
		}
		| value ADD value
		{
			/* cout << $1 << " + " << $3 << endl;
			if (isNumber($1) && isNumber($3)) {
				string reg;
				if (type == IDE) {
					reg = assign_id->getRegister();
				}
				else {
					reg = assign_arr.first->getRegister(stoll(assign_arr.second) - assign_arr.first->getArrayStart());
				}
				if (reg.compare("None") == 0) {
					reg = getRegID();
					if (type == IDE) {
						assign_id->setRegister(reg);
						registers.erase(registers.begin());
						registers.push_back(make_pair(reg, assign_id->getName()));
					}
					else {
						assign_arr.first->setRegister(stoll(assign_arr.second) - assign_arr.first->getArrayStart() , reg);
						registers.erase(registers.begin());
						registers.push_back(make_pair(reg, assign_arr.first->getName() + " " +assign_arr.second));
					}
				}
				createNumber(stoll($1) + stoll($3), reg);
				if (type == IDE) {
					assign_id->setValue(stoll($1) + stoll($3));
				}
				else {
					assign_arr.first->setValue(stoll(assign_arr.second) - assign_arr.first->getArrayStart() , stoll($1));
				}
			} */
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
	for (long long int i = 0; i < registers.size(); i++) {
		cout << registers[i].first << ":" << registers[i].second << " | ";
	}
	cout << endl;
	out.close();

}
