%{
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include "ptucc_parser.tab.h"
#include "hashtable.h"
#include "cgen.h"

/* (main source file) line tracker */
uint32_t line_num = 1;

/* check if we have verbose output */
extern bool verbose_flag;       // enable console spam
extern uint32_t yystack_depth;  // no. of yylex buffers available
/* macro support up to a limit. */
extern uint32_t max_macro;      // hashtable bin limit
extern uint32_t max_macro_max;  // hashtable hard entry limit

/* our hash table to hold the macros */
hashtable_t *mac_ht = NULL;

/* global yylex buffer index */
uint32_t yylex_bufidx = 0;

/* flex input buffers structure */
typedef struct __yybuf_state {
  YY_BUFFER_STATE state;  // flex buffer
  char *fname;            // filename we read from
  uint32_t incl_lnum;     // include file line no. tracker.
} yybuf_state;

/* flex input buffers array (bounded by max_macro_max) */
yybuf_state *yybuf_states = NULL;

/* Return true on success, false on failure */
bool set_macro(char* name, char* def);

/* Return def for macro, or NULL if no such macro is defined. */
char *get_macro(char* name);

/* pop, delete and switch our current buffer */
bool pop_delete_buffer();

/* include the file *inside* the lexer */
FILE *include_file();

/* check if we are including a file */
bool 
including_file() {
  return(yylex_bufidx > 0 &&
    yybuf_states[yylex_bufidx].fname != NULL);
}

/* increment the line count, depending if we are including a file or not */
void
increment_line_count() {
  if(including_file()) 
    {yybuf_states[yylex_bufidx].incl_lnum++;}
  else
    {line_num++;}
}

/* fetch the line count, depending if we are including a file or not */
uint32_t
fetch_line_count() {
  return including_file() ? 
    yybuf_states[yylex_bufidx].incl_lnum : line_num;
}

/* fetch the currently processed file name */
char *
fetch_incl_name() {
  return including_file() ? 
   yybuf_states[yylex_bufidx].fname : NULL;
}

/* wraper to print the formatted string requested */
void 
pwrap(char *s) {
  if(verbose_flag) {
    fprintf(stderr, "Line: %5d\ttoken: %15s\tText='%s'\n", 
      fetch_line_count(), s, yytext);
  }
}

/* wrapper to print in stderr */
void msg(char *s) {
  if(verbose_flag) {
    fprintf(stderr, "%s", s);
  }
}

%}

ID        [a-zA-Z_][0-9a-zA-Z_]*
SDIGIT    [1-9]
DIGIT     [0-9]
SNUMBER   (0|{SDIGIT}{DIGIT}*)
NUMBER    {DIGIT}{DIGIT}*
DECIMAL   ("."{NUMBER})|({SNUMBER}("."{NUMBER}?)?)
REAL      {DECIMAL}([eE][+-]?{SNUMBER})?
STRING    '(\\[ntr\'\"\\]|[^\'\\"])*'
STR_LIT   \"(\\[ntr\'\"\\]|[^\'\\"])*\"

  /* multi-line comment starting condition */
%x comment
  /* single-line comment starting condition */      
%x sl_comment 
  /* macro expansion starting condition */  
%x macro        
  /* include module starting condition */
%x incl_module

%%

@defmacro[ \r\t]+       {pwrap("DECL_MACRO"); BEGIN(macro);}
<macro>{ID} {
    /* Store macro name */
    char *mac_name = strdup(yytext);
    char *def_buf = NULL;
    size_t deflen = 0;
    char c;

    FILE *deff = open_memstream(&def_buf, &deflen);

    while((c = input())!='\n') {fputc(c, deff);}
	
    fclose(deff);
    /* perform some error checking */
    if(!set_macro(mac_name, def_buf)){
        yyerror("lexer error: failed to define macro '%s'\n", mac_name);
        if(mac_name) {free(mac_name);}
        if(deflen > 0) {free(def_buf);}
    }
    /* increment line numbers */
    increment_line_count();
    /* continue tokenization */
    BEGIN(INITIAL);
};

program     {pwrap("PROGRAM"); return KW_PROGRAM;}
begin       {pwrap("BEGIN"); return KW_BEGIN;}
end         {pwrap("END"); return KW_END;}
and         {pwrap("AND"); return KW_AND;}
array       {pwrap("ARRAY"); return KW_ARRAY;}
boolean     {pwrap("BOOLEAN"); return KW_BOOLEAN;}
char        {pwrap("CHAR"); return KW_CHAR;}
div         {pwrap("DIV"); return KW_DIV;}
do          {pwrap("DO"); return KW_DO;}
else        {pwrap("ELSE"); return KW_ELSE;}
for         {pwrap("FOR"); return KW_FOR;}
function    {pwrap("FUNCTION"); return KW_FUNCTION;}
goto        {pwrap("GOTO"); return KW_GOTO;}
if          {pwrap("IF"); return KW_IF;}
integer     {pwrap("INTEGER"); return KW_INTEGER;}
var         {pwrap("VAR"); return KW_VAR;}
mod         {pwrap("MOD"); return KW_MOD;}
not         {pwrap("NOT"); return KW_NOT;}
of          {pwrap("OF"); return KW_OF;}
or          {pwrap("OR"); return KW_OR;}
while       {pwrap("WHILE"); return KW_WHILE;}
procedure   {pwrap("PROCEDURE"); return KW_PROCEDURE;}
real        {pwrap("REAL"); return KW_REAL;}
repeat      {pwrap("REPEAT"); return KW_REPEAT;}
to          {pwrap("TO"); return KW_TO;}
result      {pwrap("RESULT"); return KW_RESULT;}
return      {pwrap("RETURN"); return KW_RETURN;}
then        {pwrap("THEN"); return KW_THEN;}
until       {pwrap("UNTIL"); return KW_UNTIL;}
downto      {pwrap("DOWNTO"); return KW_DOWNTO;}
type        {pwrap("TYPE"); return KW_TYPE;}
true        {pwrap("B_TRUE"); return KW_BOOL_TRUE;}
false       {pwrap("B_FALSE"); return KW_BOOL_FALSE;}

  /* module support */
module      {pwrap("MODULE"); return KW_MODULE;}
use         {pwrap("USE"); BEGIN(incl_module);}
  
  /* handle module includes */
<incl_module>[ \t]*       {/* eat whitespaces */}
<incl_module>[^ \t\n]+{ID}    { 
    if(include_file() == NULL) 
      {yyerror("could not open include file");}
    else {
      if(verbose_flag) {
        fprintf(stderr, "\n --\n\tincluding module: %s\n --\n", 
          yybuf_states[yylex_bufidx].fname);
      }
    }
    BEGIN(INITIAL);
  }


{ID} {
  pwrap("IDENTIFIER");
  char* def = get_macro(yytext);
  if(def==NULL) {
 		yylval.crepr = strdup(yytext);
 		return IDENT;
 	}
 	
 	if(verbose_flag) {
 	  fprintf(stderr, "Line: %5d\ttoken: %15s\tText='%s'\n", 
 	    fetch_line_count(), "MACRO_CATCH", def);
 	}
	for(int i=strlen(def); i>0; i--) 
	  {unput(def[i-1]);}
}
 						
{SNUMBER}   {
                pwrap("SNUMBER");
                yylval.crepr = strdup(yytext);
                return POSINT;
            }

{REAL}      {
                pwrap("REAL_NUM");
                yylval.crepr = strdup(yytext);
                return REAL;
            }

{STRING}    {
                pwrap("STRING");
                yylval.crepr = strdup(yytext);
                return STRING;
            }
                
{STR_LIT}   {
                pwrap("STR_LIT");
                yylval.crepr = strdup(yytext);
                return STR_LIT;
            }

  /* arithmetic operators */
"+"	        {pwrap("OP_PLUS"); return KW_OP_PLUS;}
"-"         {pwrap("OP_MINUS"); return KW_OP_MINUS;}
"*"         {pwrap("OP_MUL"); return KW_OP_MUL;}
"/"         {pwrap("OP_DIV"); return KW_OP_DIV;}

  /* relational operators */
"="         {pwrap("OP_EQ"); return KW_EQ;}
"<>"        {pwrap("OP_DIFF"); return KW_DIFF;}
"<="        {pwrap("OP_LESS_EQ"); return KW_LESS_EQ;}
"<"         {pwrap("OP_LESS"); return KW_LESS;}
">="        {pwrap("OP_GREATER_EQ"); return KW_GREATER_EQ;}
">"         {pwrap("OP_GREATER"); return KW_GREATER;}

  /* logic operators (v2) */
"&&"        {pwrap("OP_AND"); return KW_OP_AND;}
"||"        {pwrap("OP_OR"); return KW_OP_OR;}
"!"         {pwrap("OP_NOT"); return KW_OP_NOT;}

  /* assignment operators */
":="        {pwrap("OP_ASSIGN"); return KW_OP_ASSIGN;}

  /* (remaining) delimiters */
";"         {pwrap("DEL_SEMICOLON"); return KW_SEMICOLON;}
","         {pwrap("DEL_COMMA"); return KW_COMMA;}
"."         {pwrap("DEL_DOT"); return KW_DOT;}
"("         {pwrap("DEL_LPAR"); return KW_LPAR;}
")"         {pwrap("DEL_RPAR"); return KW_RPAR;}
"["         {pwrap("DEL_LBRA"); return KW_LBRA;}
"]"         {pwrap("DEL_RBRA"); return KW_RBRA;}
":"         {pwrap("DEL_COLON"); return KW_COLON;}

  /* handle single-line comments */
"//"                    {BEGIN(sl_comment);}
<sl_comment>[^\n]      /* eat up anything up to newline */
<sl_comment>\n      {
                        increment_line_count(); // increment line
                        BEGIN(INITIAL);         // go back
                    }
                      
  /* handle multi-line comments */
"(*"					{BEGIN(comment);}
<comment>[^*\n]*        /* eat anything that's not a '*' */
<comment>"*"+[^*)\n]*   /* eat up '*'s not followed by ')'s */
<comment>\n             {increment_line_count();}
<comment>"*"+")"        {BEGIN(INITIAL);}


[ \r\t]				/* skip whitespace */
\n 						{increment_line_count();}//++line_num;
<<EOF>>         {
                    /* pop one of the stacked buffers, if any */
                    if(!pop_delete_buffer()) {
                        if(yybuf_states)
                            {free(yybuf_states);}
                        flex_closure();
                        return EOF;
                    }
                }

.   {
        /* makes again, valgrind happy -- even in failures */
        yyerror("lexical error: unrecognized literal '%s'\n", yytext);
    }


%%

/* Return true on success, false on failure */
bool 
set_macro(char* name, char* def) {
  /* check if the hash table is created already */
  if(mac_ht == NULL) {
    /* try to create it */
    if((mac_ht = ht_create(max_macro, NULL)) == NULL)
      /* return error, if we can't create it. */
      {yyerror("\n -- Error: Hashtable creation failed"); return false;}
  }
  
  /* check if we can set it based on the limits */
  if(mac_ht->stored_elements >= max_macro_max) 
    {yyerror("\n -- Error: Max hash table entries reached, adjust sizes"); return false;}
  
  /* now check to find that macro */
  if(!ht_set(mac_ht, name, def)) 
    /* error, not inserted and no need to free */
    {return false;}
  else
    /* successful insertion, free duplicates */
    {free(name); free(def); return true;}
}

/* this is basically just a wrapper to ht_get */
char * 
get_macro(char* name)
  {return (ht_get(mac_ht, name));}

/* pop, delete and switch our current buffer to a previous one */
bool
pop_delete_buffer() {
  /* check if we have available buffers to clear */
  if(yylex_bufidx > 0) {
    if(verbose_flag) {
      fprintf(stderr, " --\n\tFinished including module: %s\n --\n",
        yybuf_states[yylex_bufidx].fname);
    }
    /* clear the buffers */
    fclose(yybuf_states[yylex_bufidx].state->yy_input_file);
    yy_delete_buffer(yybuf_states[yylex_bufidx].state);
    free(yybuf_states[yylex_bufidx].fname);
    yybuf_states[yylex_bufidx].state = NULL; 
    yylex_bufidx--;
    /* switch to a previous buffer */
    yy_switch_to_buffer(yybuf_states[yylex_bufidx].state);
    return true;
  } else 
    /* if we don't have one, it's probably time to close */
    {return false;}
}
 
/* include a file */
FILE *
include_file() {
  if(yylex_bufidx >= yystack_depth-1) {
    yyerror("yylex input buffer stack exhausted, current limit is: %d", 
      yystack_depth);
    return NULL;
  }
  
  char *fname = template("%s.ptuc", yytext);
  if(fname == NULL) {return NULL;}
  /* assign the current include file pointer */
  FILE *fptr = fopen(fname, "r");
  /* return if we can't open */
  if(!fptr) {
    yyerror("lexical error: couldn't open %s module", yytext);
    free(fname);
    return NULL;
  }
  
  if(yybuf_states == NULL) {
    if((yybuf_states = calloc(yystack_depth, 
          sizeof(*yybuf_states))) == NULL) {
      yyerror("\n -- Error: Could not allocate buffer stack");
      free(fname);
      return NULL;
    }
  }
  /* now save current state and set-up to switch to the next */
  yybuf_states[yylex_bufidx].state = YY_CURRENT_BUFFER;
  yylex_bufidx++;
  yybuf_states[yylex_bufidx].state = yy_create_buffer(fptr, YY_BUF_SIZE);
  yybuf_states[yylex_bufidx].fname = fname;
  yybuf_states[yylex_bufidx].incl_lnum = 1;
  /* switch the state */
  yy_switch_to_buffer(yybuf_states[yylex_bufidx].state);
  
  return fptr;
}


