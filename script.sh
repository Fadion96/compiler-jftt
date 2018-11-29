#!/bin/bash

FILES=./Testy/test*

for f in $FILES;
do
	echo $f
	echo "------------------------"
	cat $f
	echo
	./kompilator $f wynik
	./maszyna-rejestrowa wynik
	echo
	read -n 1 key
	if [[ $key = q ]] ; then
		break
	fi
	echo
done
