#pragma once

#include <stdint.h>
#include "hashtable.h"

/*
	String streams are handy for using standard C-library
	functions to produce formatted strings.
*/
typedef struct sstream {
    char *buffer;
    size_t bufsize;
    FILE *stream;
} sstream;

void ssopen(sstream *S);

void ssflush(sstream *S);

void ssclose(sstream *S);


/*
 	This function takes the same arguments as printf,
 	but returns a new string with the output value in it.
 */
char* template(
const char *pat, ...
);

/* wraper for cleaning flex and hashtable */
void flex_closure();

/*
	This is the function used to report errors in the translation.
*/
void yyerror(char const *pat, ...);

/*
	This is set to the number of calls to yyerror
 */
extern uint32_t yyerror_count;


/* This is output at the head of a c program. */
extern const char *c_prologue;

/*
 Make a C string literal out of a PTUC string literal.
 Return the corrected string (maybe the same as P).
*/
char *string_ptuc2c(char *P);
