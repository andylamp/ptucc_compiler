#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>
#include "cgen.h"
#include "ptucc_parser.tab.h"

extern FILE *yyin;
extern char *fin_name;

/* parse command line arguments (return 1 on succ. -1 on failure) */
extern int parse_args(int argc, char **argv, FILE **in);

/* close file pointers (if any) */
extern void close_fptrs();

int main(int argc, char **argv) {
    if (parse_args(argc, argv, &yyin)) {
        fprintf(stderr, "\n\n ** Parsing from %s\n\n",
                fin_name ? fin_name : "standard input");
        yyparse();
        fprintf(stderr, "\n ** End of parsing -- %s\n",
                yyerror_count > 0 ? "failed to parse given input." :
                "successfully parsed given input.");
    }
    close_fptrs();
}




