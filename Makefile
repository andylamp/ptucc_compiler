ifndef DEBUG
# Default: compile for debug
DEBUG=1
endif
#PROFILE=1

CC = gcc

BASICFLAGS= -std=c11

DEBUGFLAGS=  -g 
OPTFLAGS= -g -finline -march=native -O3 -DNDEBUG

ifeq ($(PROFILE),1)
PROFFLAGS= -g -pg 
PLFLAGS= -g -pg
else
PROFFLAGS= 
PLFLAGS=
endif

INCLUDE_PATH=-I. 

CFLAGS= -Wall -D_GNU_SOURCE $(BASICFLAGS)

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
C_SOURCES= ptucc.c ptucc_scan.c cgen.c
C_GEN=ptucc_lex.c ptucc_parser.tab.h ptucc_parser.tab.c sample001.c

C_SRC= $(C_SOURCES) $(C_GEN)

C_OBJECTS=$(C_SRC:.c=.o)

.PHONY: all tests release clean distclean

all: ptucc_scan ptucc

ptucc: ptucc.o ptucc_lex.o ptucc_parser.tab.o cgen.o
	$(CC) $(CFLAGS) -o $@ $+ $(LIBS)

ptucc_scan: ptucc_scan.o ptucc_lex.o ptucc_parser.tab.o cgen.o
	$(CC) $(CFLAGS) -o $@ $+ $(LIBS)

ptucc_lex.c: ptucc_lex.l ptucc_parser.tab.h
	$(FLEX) -o ptucc_lex.c ptucc_lex.l

ptucc_parser.tab.c ptucc_parser.tab.h: ptucc_parser.y
	$(BISON) -d ptucc_parser.y

test: ptucc
	./ptucc < sample001.ptuc > sample001.c
	gcc -Wall -std=c11 -o sample001 sample001.c
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

depend: $(C_SOURCES)
	$(CC) $(CFLAGS) -MM $(C_SOURCES) > .depend
	
clean: realclean depend

include .depend

# Create release (courses handout) archive

release: clean-release-files tinyos2.tgz

clean-release-files:
	-rm tinyos2.tgz

TARFILES= cgen.c	cgen.h	Makefile  ptucc.c  ptucc_lex.l	\
  ptucc_parser.y ptucc_scan.c  ptuclib.h  sample001.ptuc \
  README.txt


ptuc_example.tgz: $(TARFILES)
	$(MAKE) distclean
	tar czvhf ptuc_example.tgz $(TARFILES)


