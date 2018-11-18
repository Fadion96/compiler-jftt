#ifndef IDENTIFIER_H
#define IDENTIFIER_H

#include <string>
using namespace std;

enum PidType {
	IDE,
	ARR
  };

class Identifier {
private:
	string name;
	string registr = "None";
	bool assigment = false;
	PidType type;
	long long int arr_start;
	long long int arr_end;
	long long int memory_start;

public:

	Identifier (string name, PidType pid, long long int memory_start) {
		this->name = name;
		this->type = pid;
		this->arr_start = 0;
		this->arr_end = 0;
		this->memory_start = memory_start;
	}

	Identifier (string name, PidType pid, long long int arr_start, long long int arr_end, long long int memory_start) {
		this->name = name;
		this->type = pid;
		this->arr_start = arr_start;
		this->arr_end = arr_end;
		this->memory_start = memory_start;
	}

	PidType getType() {
		return this->type;
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
	long long int getArrayStart() {
		return this->arr_start;
	}
	long long int getArrayEnd() {
		return this->arr_end;
	}
	long long int getMemoryStart() {
		return this->memory_start;
	}

	void setAssigment() {
		this->assigment = true;
	}

	void setRegister(string reg){
		this->registr = reg;
	}
};

#endif
