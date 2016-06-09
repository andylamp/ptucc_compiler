# Starting code and tools

This will familiarize the reader with the starting stub and the required tools that are needed in
order to follow this guide. I assume that you have read the Introduction ([here][1]), so I won't go what's
required to *build* the starting code; instead I'll tell you how to actually grab it.

Disclaimer: It has to be noted that the starting stub *was not* created by me; it was the starting
point for a project and the license that they had on this was free-domain so...(it was created by the wizards
 that are located in the strawberry flavored cloud I was talking about -- no names!).  I am mainly saying
this because the initial project files had a number of *very* serious issues so... it's free bashing ;).

Now that we got everything out of the way, `here be dragons`<sup>&trade;</sup>!

# Grab starting archive

You grab the starting stub by using two different routes; which are the following:

1) Check out of the 'starting_stub' branch by typing in a console:
```
    git checkout -b starting_stub https://github.com/andylamp/ptucc_compiler
```

2) Alternatively, if you are not familiar or don't want to use `git` you can download it from here. It
has to be noted that going this route involves another step; extracting the archive contents, this can
be done by navigating to the folder you downloaded the archive using your console and typing in
the terminal the following: `$ tar xzvf ptuc_starting_stub.tgz`.

## Grab the patched version and skip this.

You can do that too... although I don't recommend that.

1) Check out of the 'starting_stub' branch by typing in a console:
```
    git checkout -b starting_stub_patched https://github.com/andylamp/ptucc_compiler
```
2) Grab the archive here.

# Building starting archive

Now after extracting, it's time to build and test it. Go into the extracted folder inside a linux terminal
and type the following command:

`$ ls`

You should see something like this:

```
$ ls
bad001.ptuc  cgen.c    ptucc_lex.l     README.md       sample004.ptuc
bad002.ptuc  cgen.h    ptucc_parser.y  sample001.ptuc  sample005.ptuc
bad003.ptuc  Makefile  ptucc_scan.c    sample002.ptuc  sample006.ptuc
bad004.ptuc  ptucc.c   ptuclib.h       sample003.ptuc
```

If your output looks similar to the above you are in the right place, now let's compile it by typing
the following command in the console:

`$ touch .depend; make all`

Something that looks like the following segment should be printed:

```
gcc -Wall -D_GNU_SOURCE -std=c11 -g   -I.    -c -o ptucc_scan.o ptucc_scan.c
bison -d ptucc_parser.y
flex -o ptucc_lex.c ptucc_lex.l
gcc -Wall -D_GNU_SOURCE -std=c11 -g   -I.    -c -o ptucc_lex.o ptucc_lex.c
gcc -Wall -D_GNU_SOURCE -std=c11 -g   -I.    -c -o ptucc_parser.tab.o ptucc_parser.tab.c
gcc -Wall -D_GNU_SOURCE -std=c11 -g   -I.    -c -o cgen.o cgen.c
gcc -Wall -D_GNU_SOURCE -std=c11 -g   -I.  -o ptucc_scan ptucc_scan.o ptucc_lex.o ptucc_parser.tab.o cgen.o -lfl
gcc -Wall -D_GNU_SOURCE -std=c11 -g   -I.    -c -o ptucc.o ptucc.c
gcc -Wall -D_GNU_SOURCE -std=c11 -g   -I.  -o ptucc ptucc.o ptucc_lex.o ptucc_parser.tab.o cgen.o -lfl
```

That means that you've compiled the archive correctly, if not please check the requirements section
(and esp. the program versions) again and find what's not satisfied as that's the most likely cause
of compilation failures.

# Building the sample test

If you compiled the project correctly then you should be able to run the minimal sample, as that's designed
to be executed even with the rudimentary skeleton project we have now. Thus type in the console the following

```
$ make test
```

If all went well, then the output should be something like this:

```
$ make test
./ptucc < sample001.ptuc > sample001.c
gcc -Wall -std=c11 -o sample001 sample001.c
./sample001
Hello world
```

Congratulations, you've just compiled and executed your first `ptuc` program!

Warming! If compilation fails and the error looks like this:

```
$ make test
gcc -Wall -D_GNU_SOURCE -std=c11 -g   -I.    -c -o ptucc.o ptucc.c
ptucc.c:2:30: fatal error: ptucc_parser.tab.h: No such file or directory
compilation terminated.
<builtin>: recipe for target 'ptucc.o' failed
make: *** [ptucc.o] Error 1
```

Then you've not compiled successfully the project previously, compile it and try running
`make test` again.

# Files included

The initial project should contain the files in the table below alongside with a brief
description of their intended function.

|       Filename      |     Brief description |
|:-------------------:|:------------------------------------------------:|
|    ptucc_parser.y   |  Bison syntax rules     |
|      ptucc_lex.l    |  Flex lexer rules    |
|     ptucc_scan.c    |  Perform lexical analysis only    |
|        ptucc.c      |  Perform lexical and syntax analysis    |
|       ptuclib.h     |  default includes in each generated `.c` file    |
|      cgen.{h, c}    |  `ptuc` to `C` converter helpers    |
|       Makefile      |   builds the project   |
|  bad00{1..4}.ptuc   |   sample bad files   |
| sample00{1..6}.ptuc |  sample correct files    |


# First examination

Personally, when I get my hands on a starting stub that I did not personally create I always put it
through its paces (if I can). That's because if it has any problems when I assume it has none,
it **will** most certainly create **major** debugging headaches later on (and I value my sanity).

## Does it compile?

Generally, when someone gives you a starting stub, it should compile; even if it has the bare minimum;
this can make your life quite a bit easier. It also shows (usually) that its author paid enough
attention to deliver something that's working. Since we compiled the project previously we won't
do this here.

## Pass it through `valgrind` (optional?)

Valgrind is one of my favorite tools, it works really well on almost any Linux/BSD distribution
but recent Mac OS releases have problems. Valgrind let's you profile and find errors in your program
while also giving clues on their origin -- this is **super** handy. I certainly would've missed
quite a few memory leaks if it wasn't for `valgrind`. Mastering `valgrind` is a huge task and
probably a subject to write a whole book about it so I'll only cover the very basics here.

Anyway let's run `test` using `valgrind` by typing the following:

```
$ valgrind --leak-check=full ./ptucc < ./sample001.ptuc
```

This command does *memory* checking during the execution of `ptucc` with
pipe'd argument `./sample001.ptuc`. Now you should probably quite a bit of
console spam, this is expected. At the end of the output, the summary would
be like the following:

```
==15886== LEAK SUMMARY:
==15886==    definitely lost: 240 bytes in 10 blocks
==15886==    indirectly lost: 0 bytes in 0 blocks
==15886==      possibly lost: 0 bytes in 0 blocks
==15886==    still reachable: 16,463 bytes in 4 blocks
==15886==         suppressed: 0 bytes in 0 blocks
==15886== Reachable blocks (those to which a pointer was found) are not shown.
==15886== To see them, rerun with: --leak-check=full --show-leak-kinds=all
==15886==
==15886== For counts of detected and suppressed errors, rerun with: -v
==15886== ERROR SUMMARY: 397 errors from 19 contexts (suppressed: 0 from 0)
```

This is *really* bad as our program leaks memory and probably does memory operations (read, write) in
places that it shouldn't. Now that we established that the provided code has issues, let's fix it.

# Patching up

Now, if you followed me through the `valgrind` section, you probably already know that the starting
code has quite a few issues; here we will attempt to fix them. Looking at the errors we see
that we have two kinds of errors:

 1) For leaking memory (shown at the end)
 2) For invalid memory operations (shown when executed)

Most console spam produced by `valgrind` usually is comprised out of *invalid memory operations* type
errors as these are printed immediately when they are detected. On the other hand *leaking memory*
related errors are printed as a summary in the end; that's quite sane as you'd expect the
program to end as that's when you would be certain if any memory is actually lost.

## Fix invalid memory operations errors

Let's tackle the issue by first fixing the invalid memory operation errors. If we dig through
the console spam, we can see a distinct pattern which is similar to this:

```
==15886== Invalid read of size 1
==15886==    at 0x4C35040: __GI_mempcpy (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
==15886==    by 0x4EB3171: _IO_file_xsputn@@GLIBC_2.2.5 (fileops.c:1319)
==15886==    by 0x4E884CA: vfprintf (vfprintf.c:1632)
==15886==    by 0x4E8F848: printf (printf.c:33)
==15886==    by 0x4032C3: yyparse (ptucc_parser.y:41)
==15886==    by 0x400D9E: main (ptucc.c:6)
==15886==  Address 0x52135f4 is 52 bytes inside a block of size 8,192 free'd
==15886==    at 0x4C2FD5F: realloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
==15886==    by 0x4EB0263: _IO_mem_finish (memstream.c:130)
==15886==    by 0x4EA724E: fclose@@GLIBC_2.2.5 (iofclose.c:62)
==15886==    by 0x4038A8: ssclose (cgen.c:22)
==15886==    by 0x403997: template (cgen.c:37)
==15886==    by 0x403302: yyparse (ptucc_parser.y:48)
==15886==    by 0x400D9E: main (ptucc.c:6)
==15886==  Block was alloc'd at
==15886==    at 0x4C2FB55: calloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
==15886==    by 0x4EB02F2: open_memstream (memstream.c:83)
==15886==    by 0x403859: ssopen (cgen.c:11)
==15886==    by 0x403925: template (cgen.c:29)
==15886==    by 0x403302: yyparse (ptucc_parser.y:48)
==15886==    by 0x400D9E: main (ptucc.c:6)
```

This basically says that our program attempted to perform a `read` operation on a memory that was
previously free'd; as you'd imagine this is not correct. We can see three distinct sections in the
above segment, which show the *call trees* of the following

 1) where we performed the invalid `read` operation
 2) where the memory was previously free'd and
 3) where that block of memory was originally allocated.

We know have enough information to go "hunting". We observe that the last of our own files in the
error's call tree is `ptucc_parser.y`; so let's open that first.


### Hunting the errors

#### Invalid `read` errors

Now inside `ptucc_parser.y` the line that produces the culprit is line number  41; the code looks like this:

```c
printf("int main() %s \n", $2);
```

The only place we are *reading* something is in the first argument of `printf`; this is probably
where the actual `read` error happens. The next thing we have to do is to locate where the free
happens and why it happens there. Examining the call-trees above we see that the memory is free'd
inside `cgen.c` and specifically inside `ssclose` function.

Inside `cgen.c` function `ssclose` looks like this:

```c
void ssclose(sstream* S) {
    fclose(S->stream);
}
```

This looks innocent enough at first glance by let's examine the function that `sscalled`
is called from, which is `template` and looks like this:

```c
char* template(const char* pat, ...) {
	sstream S;
	ssopen(&S);

	va_list arg;
	va_start(arg, pat);
	vfprintf(S.stream, pat, arg );
	va_end(arg);

	char* ret = ssvalue(&S);
	ssclose(&S);
	return ret;
}
```

Again this looks that's nothing wrong this implementation it at first, but if you examine this
more carefully you will see that the problem lies inside `ssvalue` and the way it returns the
`buffer` value. In order to understand that's look at the definition of `sstream`
structure and the internals of `ssopen` function.

`sstream` structure is (in `cgen.h`)
```c
typedef struct sstream {
	char *buffer;
	size_t bufsize;
	FILE* stream;
} sstream;
```

while `ssopen` function has the following implementation:
```c
void ssopen(sstream* S) {
	S->stream = open_memstream(&S->buffer, &S->bufsize);
}
```

Now you've probably never heard of `open_memstream`, but it's like `fopen` but instead of opening a physical
stream to a file it open a stream to a file in memory (RAM). Additionally `ssvalue` return the a `char`
pointer from an `sstream` structure which in our case is allocated locally inside `template`. This for some
reason creates an error when we return the buffer pointer directly from `ssvalue`. An easy fix is to
change `ssvalue` to `ssflush` so that its implementation would be:

```c
void
ssflush(sstream* S) {
  fflush(S->stream);
}
```

And change `template` function to reflect this:

```c
char* template(const char* pat, ...) {
	sstream S;
	ssopen(&S);

	va_list arg;
	va_start(arg, pat);
	vfprintf(S.stream, pat, arg );
	va_end(arg);

	ssflush(&S);
	ssclose(&S);
	return S.buffer;
}
```

If we now recompile the project and pass it through `valgrind` we would get the following:

```
==21460== LEAK SUMMARY:
==21460==    definitely lost: 240 bytes in 10 blocks
==21460==    indirectly lost: 0 bytes in 0 blocks
==21460==      possibly lost: 0 bytes in 0 blocks
==21460==    still reachable: 16,463 bytes in 4 blocks
==21460==         suppressed: 0 bytes in 0 blocks
==21460== Reachable blocks (those to which a pointer was found) are not shown.
==21460== To see them, rerun with: --leak-check=full --show-leak-kinds=all
==21460==
==21460== For counts of detected and suppressed errors, rerun with: -v
==21460== ERROR SUMMARY: 6 errors from 6 contexts (suppressed: 0 from 0)
```

That's a **huge** reduction in errors, previously we had **397** now we only have **6**. The reason we
had so many errors was that that invalid `read` was happening all over the place triggering the same
(invalid `read`) error but from different origins.

#### Fix actual memory leaks

The previously mentioned problems weren't actual *leaks* per se but caused errors nonetheless. We will now
tackle the actual leaks that are present. Now the memory leaks that are reported have the following
format:

```
==21460== 56 bytes in 1 blocks are definitely lost in loss record 8 of 10
==21460==    at 0x4C2FD5F: realloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
==21460==    by 0x4EB0263: _IO_mem_finish (memstream.c:130)
==21460==    by 0x4EA724E: fclose@@GLIBC_2.2.5 (iofclose.c:62)
==21460==    by 0x4038A6: ssclose (cgen.c:23)
==21460==    by 0x403995: template (cgen.c:38)
==21460==    by 0x403302: yyparse (ptucc_parser.y:51)
==21460==    by 0x400D9E: main (ptucc.c:6)
```

Memory errors in `valgrind` show us the *call-tree* of the allocation point, that's where we requested
this memory. Now we just examined `ssclose` and `template` functions and they allocate enough memory
to hold the required buffer inside a `sstream` structure that's returned from `template` itself.
Now let's examine one of the location that memory was allocated in order to find out the start
of the *leak-path*; thus we open `ptucc_parser.y` and get a peek at line 53 which looks like
the following:

```c
body:
    KW_BEGIN statements KW_END
        {$$ = template("{\n %s \n }\n", $2);} // <-- line 53
    ;
```

Now we are getting somewhere! Notice that `$2` argument is passed onto the `template` function
as is without freeing it anywhere inside the block `{`,`}`; as formatted variables like `$2`, `$$` are
local to that particular block. The leak happens because `template` function allocates new memory to hold
the formatted string that follows the required pattern along with enough space for the passed arguments
-- *doesn't* consume the memory passed to it, thus we have a **leak**. Finally, let's add a `free` there
to see if we see a reduction in our error count so we would have the following:

```c
body:
    KW_BEGIN statements KW_END
        {$$ = template("{\n %s \n }\n", $2); free($2);} // <-- line 53 with free
    ;
```

If you recompile and pass it through `valgrind` you should see the following:

```
==22353== LEAK SUMMARY:
==22353==    definitely lost: 192 bytes in 9 blocks
==22353==    indirectly lost: 0 bytes in 0 blocks
==22353==      possibly lost: 0 bytes in 0 blocks
==22353==    still reachable: 16,463 bytes in 4 blocks
==22353==         suppressed: 0 bytes in 0 blocks
==22353== Reachable blocks (those to which a pointer was found) are not shown.
==22353== To see them, rerun with: --leak-check=full --show-leak-kinds=all
==22353==
==22353== For counts of detected and suppressed errors, rerun with: -v
==22353== ERROR SUMMARY: 5 errors from 5 contexts (suppressed: 0 from 0)
```

OK, looks like this is it. We have **5** errors now instead of **6** and one less leak. You should mimic
this tactic in order to patch all of the leaks as they all happen for the reason described here. Note that
if you have one or more arguments in `template` that are like: `$1`, `$2`, ... `$n` just add an equal
amount of frees *after* the `template` call (e.g. `free($1); free($2); ... free($n);`). Again pass
it through `valgrind` after recompiling the project; you should see no errors reported -- but before
you whine, jump into the next section.

#### There are still leaks!

Yes, I know; this one is kind of difficult to find so I'll blow the whistle myself; touching up where we
left the output would be (after fixing the leaks described previously) like this:

```
==23221== HEAP SUMMARY:
==23221==     in use at exit: 16,458 bytes in 3 blocks
==23221==   total heap usage: 28 allocs, 25 frees, 74,479 bytes allocated
==23221==
==23221== LEAK SUMMARY:
==23221==    definitely lost: 0 bytes in 0 blocks
==23221==    indirectly lost: 0 bytes in 0 blocks
==23221==      possibly lost: 0 bytes in 0 blocks
==23221==    still reachable: 16,458 bytes in 3 blocks
==23221==         suppressed: 0 bytes in 0 blocks
==23221== Reachable blocks (those to which a pointer was found) are not shown.
==23221== To see them, rerun with: --leak-check=full --show-leak-kinds=all
==23221==
==23221== For counts of detected and suppressed errors, rerun with: -v
==23221== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
```

We can easily see that we have made 28 allocations and we performed only 25 frees; that's no good as we
see that we have a sizable chunk of our allocated memory still reachable (16,458 bytes in 3 blocks). That's
kind of a bizarre situation to be in as you have a leak but `valgrind` reports *no errors*... that's,
unfortunately quite difficult to debug I am afraid -- so if you *do* happen to encounter this in the wild
prepare for some hair pulling...

In this case (thankfully you have me!) if you look up inside the `flex` (`ptucc_lex.l`) file you see
that when our lexer finishes the `EOF` value is returned (as it should), so what could be causing this?

The answer is a bit complex... but to cut the long story short you have to *explicitly destroy* your
lexer after a successful lexical analysis; this can be done in many ways but the easiest one is
to call `yylex_destroy()` in the state that handles the end of file (`EOF`) inside flex. This happens
at line 92 of `ptucc_lex.l`:

```c
<<EOF>>     return EOF;
```

Thus we have to make the following change:

```c
<<EOF>> 	{yylex_destroy(); return EOF;}
```

If we recompile the project and pass it through `valgrind` we finally get the desired result:

```
==23508== HEAP SUMMARY:
==23508==     in use at exit: 0 bytes in 0 blocks
==23508==   total heap usage: 28 allocs, 28 frees, 74,479 bytes allocated
==23508==
==23508== All heap blocks were freed -- no leaks are possible
==23508==
==23508== For counts of detected and suppressed errors, rerun with: -v
==23508== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
```

That's all! (for now!). There are a couple of little details regarding leaks that *can* happen but are not
present in the default scenario presented here. These will be addressed when implementing
our lexer and parser respectively.

# Fixed archive and `flex`

Now that we have patched the errors and `valgrind` gives us the green light (for this basic test) we
can move on to build our lexer using `flex` [here][2].

[1]: intro.md
[2]: ptuc_lexer.md