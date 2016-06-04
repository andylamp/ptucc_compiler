#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>
#include <stdint.h>

/* flags that we parse */
bool verbose_flag = false,   // v-flag
        fout_flag = false,      // o-flag
        fin_flag = false,       // i-flag
        yystack_flag = false,   // d-flag
        macro_flag = false,     // m-flag
        help_flag = false;      // h-flag

/* in case we have a file for specific input/output */
char *fout_name = NULL,  // output .c in this file
        *fin_name = NULL;   // read the .ptuc file pointed here

FILE *fout_ptr = NULL,   // output FILE pointer            
        *fin_ptr = NULL;    // in FILE pointer

FILE **fout_ref = &fout_ptr;    // access output FILE pointer in other files

/* variable to hold stack buffer limit */
uint32_t yystack_depth = 10;

/* variable to hold the macro limit */
uint32_t max_macro = 64;
uint32_t max_macro_max = 256;

/* print usage message */
void
        print_usage();

/* parse command line arguments (return 1 on succ. -1 on failure) */
bool
        parse_args(int argc, char **argv, FILE **in);

/* close file pointers (if any) */
void
        close_fptrs();

