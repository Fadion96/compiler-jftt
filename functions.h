#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include <map>
#include <vector>
#include <iostream>
#include <string>

using namespace std;

extern map<string, Identifier*> identifierList;
extern map<string, Array*> arrayList;
extern vector<string> commands;

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
	cout << command << endl;
	commands.push_back(command);
}

void put(string reg) {
	string command = "PUT " + reg;
	commands.push_back(command);
}

void load(string reg) {
	string command = "LOAD " + reg;
	commands.push_back(command);
}

void store(string reg) {
	string command = "STORE " + reg;
	commands.push_back(command);
}

void copyreg(string reg_a, string reg_b) {
	string command = "COPY " + reg_a + " " + reg_b;
	commands.push_back(command);
}

void add(string reg_a, string reg_b) {
	string command = "ADD " + reg_a + " " + reg_b;
	commands.push_back(command);
}

void sub(string reg_a, string reg_b) {
	string command = "SUB " + reg_a + " " + reg_b;
	commands.push_back(command);
}

void half(string reg) {
	string command = "HALF " + reg;
	commands.push_back(command);
}

void inc(string reg) {
	string command = "INC " + reg;
	commands.push_back(command);
}

void dec(string reg) {
	string command = "DEC " + reg;
	commands.push_back(command);
}

void jump(string value) {
	string command = "JUMP " + value;
	commands.push_back(command);
}

void jzero(string reg, string value) {
	string command = "JZERO " + reg + " " + value;
	commands.push_back(command);
}

void jodd(string reg, string value) {
	string command = "JODD " + reg + " " + value;
	commands.push_back(command);
}

void halt() {
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
		if( i < len -1) {
			add(reg,reg);
		}
	}
}

void wypisz(){
	for(long long int i = 0; i < commands.size(); i++) {
		cout << commands[i] << endl;
	}
}

#endif
