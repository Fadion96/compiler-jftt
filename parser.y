%{
	#include <iostream>
	#include <string>
	using namespace std;
	int yylex();
	void yyerror(const char *s);
	extern int yylineno;
%}

%token DECLARE IN END
%token PID NUM
%token ASG
%token IF THEN ELSE ENDIF
%token WHILE DO ENDWHILE ENDDO
%token FOR FROM TO DOWNTO ENDFOR
%token READ WRITE
%token ADD SUB MULT DIV MOD
%token EQ NE LT GT LE GE
%token LB RB
%token SEMI COLON

%%

program:
		DECLARE declarations IN commands END
		{
			cout << "Koniec" << endl;
		}
		;

declarations:
		declarations PID SEMI
		{
			cout << "PID" << endl;
		}
		| declarations PID LB NUM COLON NUM RB SEMI
		{
			cout << "ARR" << endl;
		}
		|
		;

commands:
		commands command
		| command
		;

command:
		identifier ASG expression SEMI
		{
			cout << "Przypisanie" << endl;
		}
		| IF condition THEN commands ELSE commands ENDIF
		{
			cout << "if else" << endl;
		}
		| IF condition THEN commands ENDIF
		{
			cout << "if" << endl;
		}
		| WHILE condition DO commands ENDWHILE
		{
			cout << "while" << endl;
		}
		| DO commands WHILE condition ENDDO
		{
			cout << "do while" << endl;
		}
		| FOR PID FROM value TO value DO commands ENDFOR
		{
			cout << "from to" << endl;
		}
		| FOR PID FROM value DOWNTO value DO command ENDFOR
		{
			cout << "from downto" << endl;
		}
		| READ identifier SEMI
		{
			cout << "read" << endl;
		}
		| WRITE value SEMI
		{
			cout << "write" << endl;
		}
		;

expression:
		value
		{
			cout << "value" << endl;
		}
		| value ADD value
		{
			cout << "+" << endl;
		}
		| value SUB value
		{
			cout << "-" << endl;
		}
		| value MULT value
		{
			cout << "*" << endl;
		}
		| value DIV value
		{
			cout << "/" << endl;
		}
		| value MOD value
		{
			cout << "%" << endl;
		}
		;

condition:
		value EQ value
		{
			cout << "equals" << endl;
		}
		| value NE value
		{
			cout << "not equals" << endl;
		}
		| value LT value
		{
			cout << "less" << endl;
		}
		| value GT value
		{
			cout << "great" << endl;
		}
		| value LE value
		{
			cout << "less eq" << endl;
		}
		| value GE value
		{
			cout << "great eq" << endl;
		}
		;

value:
		NUM
		{
			cout << "Liczba" << endl;
		}
		| identifier
		{
			cout << "id" << endl;
		}
		;

identifier:
		PID
		{
			cout << "id pid" << endl;
		}
		| PID LB PID RB
		{
			cout << "id arr pid" << endl;
		}
		| PID LB NUM RB
		{
			cout << "id arr num" << endl;
		}
		;

%%

void yyerror(char const *s) {
	cerr << "Error (" << yylineno << ") " << s << endl;
	exit(1);
}

int main() {
	yyparse();
}
