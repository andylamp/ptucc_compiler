# Default: compile for debug

DEBUG ?= 1
DEBUG_GEN_FILES ?= 0
PROFILE ?= 0

CC = gcc -g

BASICFLAGS= -std=c11
DEBUGFLAGS=  -g 
OPTFLAGS= -finline -march=native -O3 -DNDEBUG

ifeq ($(PROFILE),1)
  PROFFLAGS= -pg 
  PLFLAGS= -pg
  BISONFLAGS=
else
  PROFFLAGS= 
  PLFLAGS=
  BISONFLAGS=-d --report=state --report-file=./bstate.debug
endif

INCLUDE_PATH=-I. 

CFLAGS= -Wall -D_GNU_SOURCE $(BASICFLAGS)

ifneq ($(DEBUG_GEN_FILES), 1)
SAMPLE_CFLAGS= -D_GNU_SOURCE $(BASICFLAGS)
else
SAMPLE_CFLAGS= $(CFLAGS)
endif

ifeq ($(DEBUG),1)
  CFLAGS+=  $(DEBUGFLAGS) $(PROFFLAGS) $(INCLUDE_PATH)
else
  CFLAGS+=  $(OPTFLAGS) $(PROFFLAGS) $(INCLUDE_PATH)
endif

LDFLAGS= $(PLFLAGS) $(BASICFLAGS)
LIBS=-lfl
FLEX=flex
BISON=bison

#------------------------------------------
# app
#------------------------------------------


C_PROG= ptucc ptucc_scan sample001
C_SOURCES= ptucc.c ptucc_scan.c cgen.c hashtable.c config.c
C_GEN=ptucc_lex.c ptucc_parser.tab.h ptucc_parser.tab.c sample001.c

C_SRC= $(C_SOURCES) $(C_GEN)

C_OBJECTS=$(C_SRC:.c=.o)

.PHONY: all tests release clean distclean

all: ptucc_lex.c ptucc

ptucc: ptucc.o ptucc_lex.o ptucc_parser.tab.o cgen.o hashtable.o config.o
	$(CC) $(CFLAGS) -o $@ $+ $(LIBS)

ptucc_scan: ptucc_scan.o ptucc_lex.o ptucc_parser.tab.o cgen.o hashtable.o config.o
	$(CC) $(CFLAGS) -o $@ $+ $(LIBS)

ptucc_lex.c: ptucc_lex.l ptucc_parser.tab.h
	$(FLEX) -o ptucc_lex.c ptucc_lex.l

ptucc_parser.tab.c ptucc_parser.tab.h: ptucc_parser.y
	$(BISON) $(BISONFLAGS) ptucc_parser.y

%: ptucc_scan ptucc %.ptuc
	./ptucc < $@.ptuc > $@.c
	$(CC) $(SAMPLE_CFLAGS) -o $@ $@.c
	./$@
 
test: ptucc_scan ptucc
	./ptucc < sample001.ptuc > sample001.c
	$(CC) $(SAMPLE_CFLAGS) -o sample001 sample001.c
	./sample001

#-----------------------------------------------------
# Build control
#-----------------------------------------------------

distclean: realclean
	-touch .depend
	-rm *~

realclean:
	-rm $(C_PROG) $(C_OBJECTS) $(C_GEN) .depend *.o sample001.c sample001
	-rm .depend
	-touch .depend
	
clean: realclean

include .depend

# Create release archive

release: clean-release-files ptucc.tgz

clean-release-files:
	-rm ptucc.tgz

TARFILES= cgen.c cgen.h	Makefile ptucc.c ptucc_lex.l	\
  ptucc_parser.y ptucc_scan.c  ptuclib.h \
  README.md hashtable.c hashtable.h


ptucc.tgz: $(TARFILES)
	$(MAKE) distclean
	tar czvhf ptucc.tgz $(TARFILES)


