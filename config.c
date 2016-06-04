#include "config.h"

/* parse command line arguments (return true on succ. false on failure) */
bool
parse_args(int argc, char **argv, FILE **in) {
    /* rudimentary error checking */
    if (argc < 0 || argv == NULL || in == NULL) { return false; }

    int16_t c, errflg = 0;
    while ((c = getopt(argc, argv, "vo:i:d:m:h")) != -1) {
        switch (c) {
            case 'v': {
                verbose_flag = true;
                break;
            }
            case 'o': {
                fout_name = optarg;
                fout_flag = true;
                break;
            }
            case 'i': {
                fin_name = optarg;
                fin_flag = true;
                break;
            }
            case 'd': {
                yystack_flag = true;
                uint32_t depth = (uint32_t) strtol(optarg, NULL, 10);
                if (depth == 0 || depth < 3) {
                    errflg++;
                    fprintf(stderr, "\n -- Error: Could not convert -d arg to a positive number");
                }
                else { yystack_depth = depth; }
                break;
            }
            case 'h': {
                help_flag = true;
                break;
            }
            case 'm': {
                macro_flag = true;
                uint32_t macro_len = (uint32_t) strtol(optarg, NULL, 10);
                if (macro_len == 0 || macro_len < 32) {
                    errflg++;
                    fprintf(stderr, "\n -- Error: Could not convert -m arg to a positive number");
                }
                    /* max macro entry limit is 4 times the bin limit */
                else {
                    max_macro = macro_len;
                    max_macro_max = macro_len * 4;
                }
                break;
            }
            case ':': {
                fprintf(stderr,
                        "\n\t -- Error: Option -%c requires an operand", c);
                errflg++;
                break;
            }
            case '?': {
                errflg++;
                break;
            }
        }
    }

    /*  handle help flag */
    if (help_flag) {
        if (verbose_flag || fout_flag || fin_flag || yystack_flag || macro_flag) { errflg++; }
        else { print_usage(); }
        return false;
    }

    /* errors found */
    if (errflg) {
        print_usage();
        return false;
    }


    /* check for more arguments at the end, if we have more args
       and -i flag, complain. */
    if (fin_flag) {
        if (optind != argc) {
            fprintf(stderr,
                    "\n -- Error: Selected -i flag while also inputing a file as an argument\n");
            return false;
        }
    } else {
        /* last argument will be treated as a filename for input */
        if (optind != argc) {
            fin_name = argv[argc - 1];
        }
        /* now leave it at stdin (from < op) */
    }

    /* if verbose flag, inform the user */
    if (verbose_flag) {
        fprintf(stderr, "\n -- Setting max_macro: %d, max limit: %d", max_macro, max_macro_max);
        fprintf(stderr, "\n -- Setting yystack_depth: %d", yystack_depth);
    }

    /* handle input redirection if we have an -i flag or an argument */
    if (fin_name) {
        fin_ptr = fopen(fin_name, "r");
        if (!fin_ptr) {
            fprintf(stderr, "\n -- Error: could not open %s for reading...", fin_name);
        } else {
            fprintf(stderr, "\n -- Setting yyin to %s", fin_name);
            *in = fin_ptr;
        }
    }

    /* handle output redirection if we have an -o flag */
    if (fout_name) {
        fout_ptr = fopen(fout_name, "w+");
        if (!fout_ptr) {
            fprintf(stderr, "\n -- Error: could not open %s for writting...", fout_name);
        } else {
            fprintf(stderr, "\n -- Setting outfile: %s", fout_name);
        }
    }
    return true;
}

/* print usage message */
void
print_usage() {
    fprintf(stderr, "Example Usage:");
    fprintf(stderr, "\n  ./ptucc -v verbose output (can be used in any combination)");
    fprintf(stderr, "\n  ./ptucc -i [infile]");
    fprintf(stderr, "\n  ./ptucc -i [infile] -o [outfile]");
    fprintf(stderr, "\n  ./ptucc -i [infile] -o [outfile] -d [depth]");
    fprintf(stderr, "\n  ./ptucc -i [infile] -o [outfile] -d [depth] -m [macro_limit]");
    fprintf(stderr, "\n  ./ptucc -h (prints this)");
    fprintf(stderr, "\n  ./ptucc infile.ptuc");
    fprintf(stderr, "\n  ./ptucc < infile.ptuc > outfile.c\n");
}

/* close file pointers (if any) */
void
close_fptrs() {
    if (fout_ptr) { fclose(fout_ptr); }
    if (fin_ptr) { fclose(fin_ptr); }
}
