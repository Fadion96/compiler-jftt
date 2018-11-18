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
	bool assigment = false;
	PidType type;
	long long int arr_start;
	long long int arr_end;
	long long int memory_start;

public:

	Identifier (string name, PidType pid) {
		this->name = name;
		this->type = pid;
		this->arr_start = 0;
		this->arr_end = 0;
	}

	Identifier (string name, PidType pid, long long int arr_start, long long int arr_end) {
		this->name = name;
		this->type = pid;
		this->arr_start = arr_start;
		this->arr_end = arr_end;
	}

	PidType getType() {
		return this->type;
	}

	string getName() {
		return this->name;
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

};

#endif
