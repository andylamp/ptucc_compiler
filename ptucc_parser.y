%{
#include <stdarg.h>
#include <stdio.h>	
#include "cgen.h"

extern int yylex(void);
extern int line_num;
%}

%union
{
	char* crepr;
}


%token <crepr> IDENT
%token <crepr> POSINT 
%token <crepr> REAL 
%token <crepr> STRING

%token KW_PROGRAM 
%token KW_BEGIN 
%token KW_END

%start program

%type <crepr> program_decl body statements statement_list
%type <crepr> statement proc_call arguments
%type <crepr> arglist expression

%%

program:  program_decl body  '.'   		
{ 
	/* We have a successful parse! 
		Check for any errors and generate output. 
	*/
	if(yyerror_count==0) {
		puts(c_prologue);
		printf("/* program  %s */ \n\n", $1);
		printf("int main() %s \n", $2);
		free($1); free($2);
	}
};


program_decl:
          KW_PROGRAM IDENT ';'  	
            {$$ = $2;}
          ;

body: 
    KW_BEGIN statements KW_END   	
      {$$ = template("{\n %s \n }\n", $2); free($2);}
    ;

statements: 				        	
        {$$ = ""; }
        ;
        
statements: 
        statement_list		   		
          {$$ = $1;}
        ;

statement_list: 
        statement   
          {$$ = $1;}                  
			  | statement_list ';' statement  
			    {$$ = template("%s%s", $1, $3); free($1); free($3);}
			  ; 


statement: 
        proc_call  						
          {$$ = template("%s;\n", $1); free($1);}
        ;

proc_call: 
        IDENT '(' arguments ')' 			
          {$$ = template("%s(%s)", $1, $3); free($1); free($3);}
        ;

arguments:									
      {$$ = "";}
	 	  | arglist 						
	 	    {$$ = $1;}
	 	  ;

arglist: 
       expression							
          {$$ = $1;}
       | arglist ',' expression 			
          {$$ = template("%s,%s", $1, $3); free($1); free($3);}
       ;

expression: 
          POSINT
            {$$ = $1;}
          | REAL
            {$$ = $1;}							
          | STRING 							
            {$$ = string_ptuc2c($1);}
          ;

%%

