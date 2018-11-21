#ifndef ARRAY_H
#define ARRAY_H

#include <string>
using namespace std;

class Array {
private:
	string name;
	string* registr;
	bool* assigment;
	long long int* value;
	long long int arr_start;
	long long int arr_end;
	long long int size;
	long long int memory_start;

public:

	Array (string name, long long int arr_start, long long int arr_end, long long int memory_start) {
		this->name = name;
		this->arr_start = arr_start;
		this->arr_end = arr_end;
		this->size = arr_end - arr_start + 1;
		this->memory_start = memory_start;
		this->registr = new string[size];
		fill(this->registr, this->registr + this->size, "None");
		this->assigment = new bool[size];
		fill(this->assigment, this->assigment + this->size, false);
		this->value = new long long int[size];
		fill(this->value, this->value + this->size, 0);

	}

	string getName() {
		return this->name;
	}

	string getRegister(long long int key) {
		return this->registr[key];
	}

	bool getAssigment(long long int key) {
		return this->assigment[key];
	}
	long long int getValue(long long int key) {
		return this->value[key];
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

	void setAssigment(long long int key) {
		this->assigment[key] = true;
	}

	void setRegister(long long int key, string reg){
		this->registr[key] = reg;
	}
	void setValue(long long int key, long long int value){
		this->value[key] = value;
	}
};

#endif
