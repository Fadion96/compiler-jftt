#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include <map>
#include <vector>
#include <iostream>
#include <string>

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

extern vector<pair<string, string>> registers;
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
	string reg = registers.front().first;
	vector<string> in_register = split(registers.front().second, " ");
	if (in_register[0].compare("None") != 0) {
		if (findIdetifier(in_register[0])) {
			Identifier* id = getIdentifier(in_register[0]);
			createNumber(id->getMemory(), "A");
			store(reg);
			id->setRegister("None");
		}
	}
	return reg;
}


string loadAssignReg() {
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
	return reg;
}

void storeArrayAssign(string reg) {
	if (isNumber(assign_arr.second)) {
		createNumber(assign_arr.first->getMemoryStart() + stoll(assign_arr.second), "A");			store(reg);
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

void wypisz(){
	cout << "----------------------" << endl << "KOD: " << endl << "----------------------" << endl;
	for(long long int i = 0; i < commands.size(); i++) {
		cout << commands[i] << endl;
	}
	cout << "----------------------" << endl << "Liczba poleceń: " << step << endl;
}

#endif
