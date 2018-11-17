%option yylineno
%option noyywrap
%{
  #define YYSTYPE std::string
  #include <string>
  #include <iostream>
  #include "parser.tab.hpp"
  using namespace std;
%}

%x comment
%%

"["					{BEGIN(comment);}
<comment>"]"		{BEGIN(INITIAL);}
<comment>.			{}
<comment>"\n"		{}
<comment><<EOF>> 	{/*Error*/ yyterminate();}

"DECLARE"			{return DECLARE;}

"IN"				{return IN;}

"END"				{return END;}

":="				{return ASG;}

"IF"				{return IF;}

"THEN"				{return THEN;}

"ELSE"				{return ELSE;}

"ENDIF"				{return ENDIF;}

"WHILE"				{return WHILE;}

"DO"				{return DO;}

"ENDWHILE"			{return ENDWHILE;}

"ENDDO"				{return ENDDO;}

"FOR"				{return FOR;}

"FROM"				{return FROM;}

"TO"				{return TO;}

"ENDFOR"			{return ENDFOR;}

"DOWNTO"			{return DOWNTO;}

"READ"				{return READ;}

"WRITE"				{return WRITE;}

"+"					{return ADD;}

"-"					{return SUB;}

"*"					{return MULT;}

"/"					{return DIV;}

"%"					{return MOD;}

"="					{return EQ;}

"!="				{return NE;}

"<"					{return LT;}

">"					{return GT;}

"<="				{return LE;}

">="				{return GE;}

"("					{return LB;}

")"					{return RB;}

";"					{return SEMI;}

":"					{return COLON;}

[0-9]+				{yylval = (yytext); return NUM;}

[_a-z]+				{yylval = (yytext); return PID;}

[ \t\n]				{}

.					{/*mozliwy error*/}

%%
