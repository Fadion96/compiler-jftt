#ifndef ARRAY_H
#define ARRAY_H

#include <string>
using namespace std;

class Array {
private:
	string name;
	long long int arr_start;
	long long int arr_end;
	long long int memory_start;

public:

	Array (string name, long long int arr_start, long long int arr_end, long long int memory_start) {
		this->name = name;
		this->arr_start = arr_start;
		this->arr_end = arr_end;
		this->memory_start = memory_start;
	}

	string getName() {
		return this->name;
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

};

#endif
