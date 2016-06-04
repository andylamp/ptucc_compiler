#pragma once

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include <errno.h>

#define writeString(x) printf("%s",(x))
#define writeInteger(x) printf("%d",(x))
#define writeFloat(x) printf("%f", (x))
#define writeReal(x) printf("%g",(x))

#define BUFSIZE 1024

char *readString() {
    char buffer[BUFSIZE];
    buffer[0] = '\0';
    fgets(buffer, BUFSIZE, stdin);
    /* strip newline from the end */
    uint32_t blen = strlen(buffer);
    if (blen > 0 && buffer[blen - 1] == '\n')
        buffer[blen - 1] = '\0';
    return strdup(buffer);
}

#undef BUFSIZE

/*
  this is much more safe and concise that just 
  using atoi, atof that the original implementation
  used 
*/
int readInteger() {
    char *s = readString();
    uint32_t val = (uint32_t) strtol(s, NULL, 10);
    free(s);
    return val;
}

double readReal() {
    char *s = readString();
    double val = strtod(s, NULL);
    free(s);
    return val;
}

