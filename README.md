
Instructions for runnng the example
------------------------------------


1) Create a new directory and change into it

% mkdir  ptuc_example
% cd ptuc_example

2) Copy the .tar file in there and unpack it

% cp <download-dir/ptuc_example.tgz .
% tar xzvf ptuc_example.tgz

3) Build it

% touch .depend
% make
gcc -Wall -D_GNU_SOURCE -std=c11 -g   -I.    -c -o ptucc_scan.o ptucc_scan.c
bison -d ptucc_parser.y
flex -o ptucc_lex.c ptucc_lex.l
gcc -Wall -D_GNU_SOURCE -std=c11 -g   -I.    -c -o ptucc_lex.o ptucc_lex.c
gcc -Wall -D_GNU_SOURCE -std=c11 -g   -I.    -c -o ptucc_parser.tab.o ptucc_parser.tab.c
gcc -Wall -D_GNU_SOURCE -std=c11 -g   -I.    -c -o cgen.o cgen.c
gcc -Wall -D_GNU_SOURCE -std=c11 -g   -I.  -o ptucc_scan ptucc_scan.o ptucc_lex.o ptucc_parser.tab.o cgen.o -lfl
gcc -Wall -D_GNU_SOURCE -std=c11 -g   -I.    -c -o ptucc.o ptucc.c
gcc -Wall -D_GNU_SOURCE -std=c11 -g   -I.  -o ptucc ptucc.o ptucc_lex.o ptucc_parser.tab.o cgen.o -lfl

4) If it built correctly, try the test

% make test
./ptucc < sample001.ptuc > sample001.c
gcc -Wall -std=c11 -o sample001 sample001.c
./sample001
Hello world


5) Have a good study !!

