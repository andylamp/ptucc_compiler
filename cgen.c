#include <assert.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdint.h>
#include "cgen.h"

extern uint32_t line_num;
extern uint32_t yylex_bufidx;
extern hashtable_t *mac_ht;

extern int yylex_destroy();

extern uint32_t fetch_line_count();

extern char *fetch_incl_name();

extern bool including_file();

uint32_t yyerror_count = 0;

const char *c_prologue =
        "#include \"ptuclib.h\"\n"
                "\n";

void
ssopen(sstream *S) { S->stream = open_memstream(&S->buffer, &S->bufsize); }

void
ssflush(sstream *S) { fflush(S->stream); }

void
ssclose(sstream *S) { fclose(S->stream); }

/* wraper for cleaning flex and hashtable */
void
flex_closure() {
    yylex_destroy();
    ht_destroy(mac_ht);
}

char*
template(
const char *pat, ...
)
{
sstream S = {0};
ssopen(&S);
va_list arg;
va_start(arg, pat);
vfprintf(S
.stream, pat, arg);
va_end(arg);

ssflush(&S);
ssclose(&S);
return S.
buffer;
}

/* Helper functions */

char *
string_ptuc2c(char *P) {
    if (P == NULL) { return P; }
    /* Just check and change the first and last characters */
    uint32_t len = strlen(P);
    /* less than three as P in single chars is "'a'\0"
       so that's basically 3 characters plus null
       like so: [', a, ', \0]
       */
    if (len < 3) { return P; }
    else {
        P[0] = '"';
        P[len - 1] = '"';
        return P;
    }
}


/*
	Report errors 
*/
void
yyerror(char const *pat, ...) {
    va_list arg;

    if (including_file()) {
        fprintf(stderr,
                " -- \n\tError in include file: %s (depth: %d)\n",
                fetch_incl_name(), yylex_bufidx);
    }

    fprintf(stderr, "\n\tline %d: ", fetch_line_count());


    va_start(arg, pat);
    vfprintf(stderr, pat, arg);
    va_end(arg);

    yyerror_count++;
    fprintf(stderr, "\n --\n");
}




