#ifndef IDENTIFIER_H
#define IDENTIFIER_H

#include <string>
using namespace std;


class Identifier {
private:
	string name;
	string registr = "None";
	bool assigment = false;
	long long int value = 0;
	long long int memory;

public:

	Identifier (string name, long long int memory) {
		this->name = name;
		this->memory = memory;
	}

	string getName() {
		return this->name;
	}

	string getRegister() {
		return this->registr;
	}

	bool getAssigment() {
		return this->assigment;
	}

	long long int getMemory() {
		return this->memory;
	}

	long long int getValue(){
		return this->value;
	}

	void setValue(long long int value){
		this->value = value;
	}

	void setAssigment() {
		this->assigment = true;
	}

	void setRegister(string reg){
		this->registr = reg;
	}
};

#endif
