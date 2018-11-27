#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include <map>
#include <vector>
#include <iostream>
#include <string>
#include <stack>

using namespace std;

enum assign_type {
	IDE,
	ARR
};

extern void yyerror(const char *s);

extern map<string, Identifier*> identifierList;
extern map<string, Array*> arrayList;
extern vector<string> commands;
extern long long int step;

extern vector<string> registers;
extern enum assign_type type;
extern Identifier* assign_id;
extern pair<Array*, string> assign_arr;


bool findIdetifier(string key) {
	if(identifierList.find(key) != identifierList.end()){
		return true;
	}
	return false;
}

bool findArray(string key) {
	if(arrayList.find(key) != arrayList.end()){
		return true;
	}
	return false;
}

Identifier* getIdentifier(string key) {
	return identifierList[key];
}

Array* getArray(string key) {
	return arrayList[key];
}

bool isNumber(string key){
	try{
		int i = stoi(key);
		return true;
	}
	catch(exception const & e) {
		return false;
	}
}

vector<string> split(string text, string delimiter) {
	vector<string> list;
	size_t pos = 0;
	string token;
	while ((pos = text.find(delimiter)) != string::npos) {
		token = text.substr(0, pos);
		list.push_back(token);
		text.erase(0, pos + delimiter.length());
	}
	list.push_back(text);
	return list;
}

void get(string reg){
	string command = "GET " + reg;
	step++;
	commands.push_back(command);
}

void put(string reg) {
	string command = "PUT " + reg;
	step++;
	commands.push_back(command);
}

void load(string reg) {
	string command = "LOAD " + reg;
	step++;
	commands.push_back(command);
}

void store(string reg) {
	string command = "STORE " + reg;
	step++;
	commands.push_back(command);
}

void copyreg(string reg_a, string reg_b) {
	string command = "COPY " + reg_a + " " + reg_b;
	step++;
	commands.push_back(command);
}

void add(string reg_a, string reg_b) {
	string command = "ADD " + reg_a + " " + reg_b;
	step++;
	commands.push_back(command);
}

void sub(string reg_a, string reg_b) {
	string command = "SUB " + reg_a + " " + reg_b;
	step++;
	commands.push_back(command);
}

void half(string reg) {
	string command = "HALF " + reg;
	step++;
	commands.push_back(command);
}

void inc(string reg) {
	string command = "INC " + reg;
	step++;
	commands.push_back(command);
}

void dec(string reg) {
	string command = "DEC " + reg;
	step++;
	commands.push_back(command);
}

void jump(string value) {
	string command = "JUMP " + value;
	step++;
	commands.push_back(command);
}

void jzero(string reg, string value) {
	string command = "JZERO " + reg + " " + value;
	step++;
	commands.push_back(command);
}

void jodd(string reg, string value) {
	string command = "JODD " + reg + " " + value;
	step++;
	commands.push_back(command);
}

void halt() {
	step++;
	commands.push_back("HALT");
}


string decToBin(long long int number) {
	if(number == 0) {
		return "0";
	}
	else if(number == 1) {
		return "1";
	}
	else if(number % 2 == 0) {
		return decToBin(number / 2) + "0";
	}
	else {
		return decToBin(number / 2) + "1";
	}
}

void createNumber(long long int number, string reg) {
	string bin = decToBin(number);
	long long int len = bin.size();

	sub(reg,reg);
	for(long long int i = 0; i < len; ++i){
		if(bin[i] == '1') {
			inc(reg);
		}
		if( i < len - 1) {
			add(reg,reg);
		}
	}
}

string getRegID(){
	string reg = registers.front();
	registers.erase(registers.begin());
	registers.push_back(reg);
	return reg;
}

void storeArrayAssign(string reg) {
	if (isNumber(assign_arr.second)) {
		createNumber(assign_arr.first->getMemoryStart() + stoll(assign_arr.second), "A");
		store(reg);
	}
	else if (findIdetifier(assign_arr.second)) {
		Identifier* tmp = getIdentifier(assign_arr.second);
		if (tmp->getAssigment()) {
			string tmp_reg = getRegID();
			createNumber(tmp->getMemory(), "A");
			load(tmp_reg);
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

void storeIdeAssign(string reg) {
	createNumber(assign_id->getMemory(), "A");
	store(reg);
}

bool startsWith(string mainStr, string toMatch) {
	if (mainStr.find(toMatch) == 0) {
		return true;
	}
	return false;
}

bool endsWith(string mainStr, string toMatch) {
	if (mainStr.length() >= toMatch.length()) {
		return (0 == mainStr.compare(mainStr.length() - toMatch.length(), toMatch.length(), toMatch));
	} else {
		return false;
	}
}

void fixJump(long long int j) {
	string jump;
	if (commands[j] == "JUMP -1") {
		jump = "JUMP " + to_string(step);
	}
	else if (startsWith(commands[j], "JZERO") && endsWith(commands[j], "-1")) {
		jump = commands[j].substr(0, commands[j].find("-1")) + to_string(step);
	}
	commands[j] = jump;
}

pair<string,string> loadValuesToRegister(string first, string second) {
	string reg_a;
	string reg_b;
	if (isNumber(first)) {
		reg_a = getRegID();
		createNumber(stoll(first), reg_a);
		if (isNumber(second)) {
			reg_b = getRegID();
			createNumber(stoll(second), reg_b);

		}
		else {
			vector<string> add_value = split(second, " ");
			if (findIdetifier(add_value[0])) {
				Identifier* add_comp = getIdentifier(add_value[0]);
				if (add_comp->getAssigment()) {
					reg_b = getRegID();
					createNumber(add_comp->getMemory(), "A");
					load(reg_b);

				}
				else {
					string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
					errorMessage.append(add_value[0]);
					yyerror(errorMessage.c_str());
				}
			}
			else if (findArray(add_value[0])) {
				Array* add_arr = getArray(add_value[0]);
				if (isNumber(add_value[1])) {
					reg_b = getRegID();
					createNumber(add_arr->getMemoryStart() + stoll(add_value[1]), "A");
					load(reg_b);

				}
				else if (findIdetifier(add_value[1])) {
					Identifier* tmp_id = getIdentifier(add_value[1]);
					if (tmp_id->getAssigment()) {
						string add_tmp = getRegID();
						createNumber(tmp_id->getMemory(), "A");
						load(add_tmp);
						reg_b = getRegID();
						createNumber(add_arr->getMemoryStart(), "A");
						add("A", add_tmp);
						load(reg_b);

					}
					else {
						string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
						errorMessage.append(add_value[1]);
						yyerror(errorMessage.c_str());
					}
				}
			}
		}
	}
	else {
		vector<string> first_comp = split(first, " ");
		if (findIdetifier(first_comp[0])) {
			Identifier* first_id = getIdentifier(first_comp[0]);
			if (first_id->getAssigment()){
				reg_a = getRegID();
				createNumber(first_id->getMemory(), "A");
				load(reg_a);
			}
			else {
				string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
				errorMessage.append(first_comp[0]);
				yyerror(errorMessage.c_str());
			}
			if (isNumber(second)) {
				reg_b = getRegID();
				createNumber(stoll(second), reg_b);

			}
			else {
				vector<string> second_comp = split(second, " ");
				if (findIdetifier(second_comp[0])) {
					Identifier* second_id = getIdentifier(second_comp[0]);
					if (second_id->getAssigment()){
						reg_b = getRegID();
						createNumber(second_id->getMemory(), "A");
						load(reg_b);
					}
					else {
						string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
						errorMessage.append(second_comp[0]);
						yyerror(errorMessage.c_str());
					}
				}
				else if (findArray(second_comp[0])) {
					Array* second_arr = getArray(second_comp[0]);
					if (isNumber(second_comp[1])) {
						reg_b = getRegID();
						createNumber(second_arr->getMemoryStart() + stoll(second_comp[1]), "A");
						load(reg_b);

					}
					else if (findIdetifier(second_comp[1])) {
						Identifier* tmp_id = getIdentifier(second_comp[1]);
						if (tmp_id->getAssigment()) {
							string add_tmp = getRegID();
							createNumber(tmp_id->getMemory(), "A");
							load(add_tmp);
							createNumber(second_arr->getMemoryStart(), "A");
							add("A", add_tmp);
							reg_b = getRegID();
							load(reg_b);

						}
					}
				}
			}
		}
		else if (findArray(first_comp[0])){
			Array* first_array = getArray(first_comp[0]);
			if (isNumber(first_comp[1])) {
				reg_a = getRegID();
				createNumber(first_array->getMemoryStart() + stoll(first_comp[1]), "A");
				load(reg_a);
			}
			else if (findIdetifier(first_comp[1])) {
				Identifier* tmp = getIdentifier(first_comp[1]);
				if (tmp->getAssigment()) {
					string tmp_reg = getRegID();
					createNumber(tmp->getMemory(), "A");
					load(tmp_reg);
					reg_a = getRegID();
					createNumber(first_array->getMemoryStart(), "A");
					add("A", tmp_reg);
					load(reg_a);
				}
				else {
					string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
					errorMessage.append(first_comp[1]);
					yyerror(errorMessage.c_str());
				}
			}
			if (isNumber(second)) {
				reg_b = getRegID();
				createNumber(stoll(second), reg_b);

			}
			else {
				vector<string> second_comp = split(second, " ");
				if (findIdetifier(second_comp[0])) {
					Identifier* second_id = getIdentifier(second_comp[0]);
					if (second_id->getAssigment()){
						reg_b = getRegID();
						createNumber(second_id->getMemory(), "A");
						load(reg_b);

					}
					else {
						string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
						errorMessage.append(second_comp[0]);
						yyerror(errorMessage.c_str());
					}
				}
				else if (findArray(second_comp[0])) {
					Array* second_arr = getArray(second_comp[0]);
					if (isNumber(second_comp[1])) {
						reg_b = getRegID();
						createNumber(second_arr->getMemoryStart() + stoll(second_comp[1]), "A");
						load(reg_b);

					}
					else if (findIdetifier(second_comp[1])) {
						Identifier* tmp_id = getIdentifier(second_comp[1]);
						if (tmp_id->getAssigment()) {
							string add_tmp = getRegID();
							createNumber(tmp_id->getMemory(), "A");
							load(add_tmp);
							reg_b = getRegID();
							createNumber(second_arr->getMemoryStart(), "A");
							add("A", add_tmp);
							load(reg_b);

						}
						else {
							string errorMessage = "Odwołanie do niezainicjowanej zmiennej ";
							errorMessage.append(second_comp[1]);
							yyerror(errorMessage.c_str());
						}
					}
				}
			}
		}
	}
	return make_pair(reg_a,reg_b);
}

void wypisz(){
	cout << "----------------------" << endl << "KOD: " << endl << "----------------------" << endl;
	for(long long int i = 0; i < commands.size(); i++) {
		cout << i << " " << commands[i] << endl;
	}
	cout << "----------------------" << endl << "Liczba poleceń: " << step << endl;
}

#endif
