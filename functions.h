#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include <map>

using namespace std;

extern map<string, Identifier*> identifierList;

bool findIdetifier(string key) {
	if(identifierList.find(key) != identifierList.end()){
		return true;
	}
	return false;
}

#endif
