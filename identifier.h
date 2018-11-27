#ifndef IDENTIFIER_H
#define IDENTIFIER_H

#include <string>
using namespace std;


class Identifier {
private:
	string name;
	bool assigment = false;
	bool iterator = false;
	long long int memory;

public:

	Identifier (string name, long long int memory) {
		this->name = name;
		this->memory = memory;
	}
	Identifier (string name, long long int memory, bool iterator) {
		this->name = name;
		this->memory = memory;
		this->iterator = iterator;
	}

	string getName() {
		return this->name;
	}
	bool getAssigment() {
		return this->assigment;
	}

	long long int getMemory() {
		return this->memory;
	}

	bool getIterator(){
		return this->iterator;
	}

	void setAssigment() {
		this->assigment = true;
	}
};

#endif
