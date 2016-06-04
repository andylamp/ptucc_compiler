# Creating the Lexer for `ptuc`

In this section we will tackle the creation of our *lexical* analyzer that understands and tokenizes
the `ptuc` language. For this task, we will use a tool called `flex` (as previously mentioned); which
is *different* than `jflex` and other programs with similar name. The only thing that's remotely compatible
with `flex` is `lex`, which `flex` is based on; but since `flex` is a superset of the features provided
by `lex` I cannot guarantee that the material and techniques used here will be directly applicable
to `lex`.

# Basic anatomy of a `flex` (`.l`) file

A typical `flex` file is comprised out of three sections which can the following:

* User code section (optional)
* Definition section (decl. of *name* def. and *starting* conditions)
* Rule section (actual input matching)
* User code section (optional)

Rule section is enclosed within `%%` brackets and the *top* user code section must be enclosed in
 `{%`, `%}` as shown below or using `%top{ ... }`.

```c
{%
user code
%}
def. section
%%
rule section
%%
user code
```

Although *optional*, the top user code section is quite commonly used as one would normally find it
the perfect place for including files, declaring function prototypes for later use and so on --
handy, to say the least. For example this section in our starting stub looks like following:

```c
%{
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "ptucc_parser.tab.h"
#include "cgen.h"

int line_num = 1;

/*
	A primitive macro facility:
	just one macro is allowed to be defined!
*/
#define MAXMACRO 32
char* mactable[MAXMACRO][2];
int mactable_size = 0;

/* Return 1 on success, 0 on failure (macro table full) */
int set_macro(char* name, char* def);

/* Return def for macro, or NULL if no such macro is defined. */
char* get_macro(char* name);

%}
```

All these variables can be used in both definition and rule sections as we will later see; if they were
placed only in the bottom user code section this would not be possible. Keep in mind that Finally all
code inside the *user code sections* is copied *as-is* to the processed file. Additionally comments in
the *rule* and *definition*  sections must be padded with at least one white-space (` `), otherwise `flex`
treats them as rules; this is illustrated in the following example:

```c
    /* this is a valid comment */
ID      [a-zA-Z_][0-9a-zA-Z_]*
/* this is not a valid comment */
```


# Regular Expressions

The heart of `flex` resides with *regular expressions* as its job is to basically *match* the input to a
specific rule-set we instruct it to. Basic knowledge of them is assumed; so if you don't know a quick
introduction to them would be the [Examples][1] section of Wikipedia. An invaluable tool for evaluating
*regexp* in general is [regex101][2] that provides both analysis and testing of regular expressions -- it's
really awesome and handy as f**k.

# Populating `flex` definitions

First of all, our starting stub has already some sample code that performs some useful tasks already, which are
shown below.

```c
ID      [a-zA-Z_][0-9a-zA-Z_]*
DIGIT   [0-9]
NUMBER  {DIGIT}{DIGIT}*
DECIMAL ("."{NUMBER})|({NUMBER}("."{NUMBER}?)?)
REAL    {DECIMAL}([eE][+-]?{NUMBER})?
STRING  '[^'\n]*'

%x comment
%x macro
```


In the above segment we can see that the named definitions have the following syntax:

```
def_name definition
```

and starting conditions have the following:

```
%x cond_name
%s cond_name
```

## Named definitions

Named definitions are used to simplify the process of writing rules; so for example we can do the following:

```c
DIGIT   [0-9]
NUMBER  {DIGIT}{DIGIT}*
```

The first definition is comprised out of *exactly* one (`1`) digit in the range `[0, 9]` so we intuitively
labeled that named def. `DIGIT`. Moreover a `NUMBER` is comprised out of *at least* one (`1`) or more
digits of that range so a *regular expression* that matches that would be the one shown above:
`{DIGIT}{DIGIT}*`, which does exactly what we previously said. It has to be noted that the previous expression
is equivalent to `[0-9][0-9]*` but usually it's much more readable to compose rules out of descriptive named
definitions especially when dealing with more complex rules.

If you don't understand any of the rules, go to [regex101][2] and play with them, you'll gain quite more by
fiddling with them yourself.

## Starting conditions

There are cases where we want to invoke a custom rule after we match a particular character or sequence;
that's not something that can be done using named definitions so `flex` supports two *starting conditions* which
do exactly that. Their types are *inclusive* and *exclusive* which are indicated by `%s` and `%x` respectively.
For our intents and purposes we will only use the *exclusive* start condition type. Conditions are called using
a special function `BEGIN`, so we would invoke one like this: `BEGIN(comment)`. Finally an
*exclusive* (`%x`) condition means that as long as another `BEGIN` action is not invoked no other
rules that have starting condition will be active.

# Populating `flex` rules

In order to populate the `flex` rules we have to *carefully* read our language specification [here][3], I'll
only here compare the changes with the final file and only mention any noteworthy changes.

## `flex` tokens

`flex` is tasked to *match* the input against our rules; *tokens* are what we use to let `bison` know that we
 a *matched* a `flex` rule against our current input. Tokens nothing more than `integer` values inside
 an enumeration located in `parser_fname.tab.h` which is generated for us automatically by invoking `bison`
 with the `-d` argument and our parser file.

 A token to be *valid* in both `bison` and `flex` must be *first* declared as a `%token` inside `bison` like so

 ```c
 %token IDENT
 ```

and then `bison` can automatically generate the token stub by executing: `bison -d my_parser.y` as
previously mentioned. The generated file would have the name of `my_parser.tab.h` which would be then
 included in the `flex` (`.l`) file. It has to be noted that not all rules are required to return a
 `token` but most of them should.

## Handling language reserved words

Each language has a set of *reserved* words that perform a specific function and *cannot* be
used for any other purpose (e.g. keywords, operators etc). The way we handle them is pretty
simple with a slight variation should our language be case *sensitive* or *insensitive* (we would require a
slightly more expressive reg. exp. to represent our rule).

Usually we match a `keyword` and return that specific token; this is all done directly in the rules section
as it is shown for some operators below:

```c
"+"     {return KW_OP_PLUS;}
"-"     {return KW_OP_MINUS;}
"*"     {return KW_OP_MUL;}
"/"     {return KW_OP_DIV;}
```

This directly matches the string characters shown in the left with the rule definition shown inside the `{`, `}`;
thus when  for example we see a `+` sign we return the `KW_OP_PLUS` token. In a similar fashion `keywords` would
be matched as follows:

```c
begin   {return KW_BEGIN;}
end     {return KW_END;}
```

This again matches the literal string shown in the left (`begin` and `end`) to their respective tokens
inside `{`, `}`. Finally named definitions can be used as matching rules themselves as such:

```c
{REAL}  {return REAL;}
```

The above matches a `REAL` named definition and returns if it was indeed matches against our input the `REAL`
token.

## Handling strings

As is indicated in `ptuc` spec. we treat strings that have single and double quotes equally and also we allow
a limited set of special escape characters (`\n`, `\t`, `\r`, `\'`, `\"`) and no multi-line strings. In our
starting stub we had the following named definition for string classification:

```c
STRING  '[^'\n]*'
```

This is extremely inadequate, as what that only does is handle *single* quoted strings and is naively ended
in either a newline character (`\n`) or in a single quote (`'`). This does not handle the escape characters
nor something like this: `writeString('PI="nice"');` in which we should throw and error as `"` is an escape
character and cannot be written like that; instead this would be written as: `writeString('PI=\"nice\"');`.
This is accomplished by the following two named definitions:

```c
STRING    '(\\[ntr\'\"\\]|[^\'\\"])*'
STR_LIT   \"(\\[ntr\'\"\\]|[^\'\\"])*\"
```

This allows us to capture both types of strings in two classes, one for each. The philosophy behind this is
pretty simple as the first part `\\[ntr\'\"\\]` is responsible for capturing the allowed
*escape characters* while the other `[^\'\\"]` is responsible for capturing the remaining allowed characters.
We also have to classes as the strings that are in single quotes need to be converted into double quoted strings
for `C` conversion, hence we need to have a distinct token in order know when to perform that conversion.

## Handling macros

Now as we saw in the specification we have baked into `ptuc` a rudimentary macro support facility which is pretty
straightforward. Already in our starting stub we have a working macro substitution framework -- but it's really
slow and it has a big limitation as its size is fixed at compile time. Let's take a look at how macros are
detected and we will deal with that issue later on.


Again we use a starting condition in order to fully process a macro which is placed in the definition section and
looks like this:
```c
  /* macro expansion starting condition */
%x macro
```

Now in the rules section we have a *regular-expression* match that *triggers* our macro starting condition; that
particular rule follows:
```c
@defmacro[ \r\t]+       BEGIN(macro);
```
This rule literally matches "@defmacro" string and *expects* to discard *at least one* or more characters
inside the class: `[ \r\t]+`. Then we have the matched rule that follows to invoke the *exclusive* `<macro>`
starting condition in order process the macro definition. The only rule that begins with this starting
condition must be followed by an `<identifier>` as well in order to be successfully match (otherwise an error
is thrown). The rule follows in full.

```c
<macro>{ID} {
    /* Store macro name */
    char* name = strdup(yytext);
    char* def = NULL;
    size_t deflen = 0;
    char c;

    FILE* deff = open_memstream(&def, &deflen);

    while((c=input())!='\n') {fputc(c, deff);}
    fclose(deff);

    if(!set_macro(name, def))
        {yyerror("lexer error: failed to define macro '%s'\n", name);}
    BEGIN(INITIAL);
};
```

There are a couple of things that happen here; the first thing is that we use `open_memstream` to open a
file *in-memory* so that we can read to the *value* of the macro; this is done inside the `white` loop as we
read the characters until we reach the end of the line. The name of the macro is the current value
of `yytext` (as it is matched from the `ID` named def.).

We then use `set_macro` function to insert the `Key`, `Value` pair inside our macro table. Unfortunately this
method that's used in our starting stub is not only slow (as we pay always the cost of traversing a list,
`O(n)`) it's also limited in size at compile time. The final version uses a *hashtable* (and the one from
[here][4]) which is both faster (`O(1)` lookup cost) and more flexible as a data structure. In the end both
`set_macro` and `get_macro` are wrappers to the respective `ht_get` and `ht_set` `hashtable` functions that
attempt to set and get a (`Key`, `Value`) pair.


## Handling identifiers

Identifiers thankfully are pretty straight forward in their implementation and the rule is the same as in our
starting stub. But let's check it out in order to discern how we perform a *macro* **substitution** if needed.
The full matching rule for `identifiers` follows.

```c
{ID}    {
    char* def = get_macro(yytext);
    if(def==NULL) {
        yylval.crepr = strdup(yytext);
        return IDENT;
    }

    for(int i=strlen(def); i>0; i--)
        {unput(def[i-1]);}
 }
```

There are a couple of things happening here but the logic behind it is this -- since we perform *macro*
substitution **inside** our lexer (our parser has no idea of this) we have to check at every `identifier`
if that is a macro and needs to have its value replaced. Let's illustrate this with an example,
say we have the following:

```pascal
@defmacro COOL_DIGIT 10

(* and later on *)
x := COOL_DIGIT;
```

now `x := COOL_DIGIT` is an *assignment* statement, hence `COOL_DIGIT` will be *matched* as an *identifier* as
who's to say that it is not another `variable` or `macro`? Thus, when we perform an `identifier` input matching
we check if the value of `yytext` is the `key` of a (`Key`, `Value`) pair in our `macro` hashtable. That's
accomplished by this

```c
char* def = get_macro(yytext);
```

In case `def` turns out to be `NULL`, then this is definitely not a macro so we return that we *matched* an
`identifier`; in the case that `def` is *not* `NULL` then we have to substitute its value (by pushing it on
our input buffer) in order to be read by `flex` afterwards. That's what that `for`-loop is for, please also
notice that we substitute the value in reverse order (why?).

## Handling numbers

Handling numbers is a bit more complex than the named definitions provided in our starting stub; that mainly
due to the fact that as per our specification we *do not* allow the integer part to have starting zeros; thus
with our initial definition this `x := 0001` would be a perfectly legal `NUMBER`. To alleviate this we create
another class called `SDIGIT` that includes the range `[1, 9]` that will be used always to represent the
first digit of a potential integer part. The final result is shown below.

```c
SDIGIT    [1-9]
DIGIT     [0-9]
SNUMBER   {SDIGIT}{DIGIT}*
NUMBER    {DIGIT}{DIGIT}*
DECIMAL   ("."{NUMBER})|({SNUMBER}("."{NUMBER}?)?)
REAL      {DECIMAL}([eE][+-]?{SNUMBER})?
```

Please note that we kept both `SNUMBER` and `NUMBER` as we have to allow starting zeros in the fraction part of
a floating point number (e.g. `.0011`, `1.002e+12`).

## Handling comments

Comments are important on *reading* a source file but not when compiling it -- hence we just discard them. There
are a couple of things that we have to take care of such as incrementing the line counter on multi-line comments
and handling some edge cases.

On our starting stub we have an almost complete implementation on how to discard *multi-line comments*, but
nothing is done for *single-line* ones. Let's look at how multi-line comments are handled first.

First of, in the definition section we have the *exclusive* starting class
```c
  /* multi-line comment class */
%x comment
```

And later on deep inside the rule section we have the actual rules that discard the comments.
```c
"(*"					BEGIN(comment);
<comment>[^*\n]*        /* eat anything that's not a '*' */
<comment>"*"+[^*)\n]*   /* eat up '*'s not followed by ')'s */
<comment>\n             ++line_num;
<comment>"*"+")"        BEGIN(INITIAL);
```

As you might imagine the first rule is triggered when the input (current value of `yytext`) is `(*` then
we might go to any of the four (`4`) available classes depending on the input. Inspecting the comments
it's pretty straight-forward to understand what these do but please also do remember that *unless* we exit
the *exclusive* starting condition (`<comment>`) no other rule than these four (`4`) will be tried. Thus if
we don't encounter the fourth rule we might as well eat up the whole file (leading to an error in the end).

Using a similar philosophy *single-line* comments could be implemented like this.

In the definition section we will have to define a new (*exclusive*) starting condition like this:

```c
  /* single-line comment class */
%x sl_comment
```

Then using fewer cases, as we are bounded by the **single** line constraint; thus our hard end limit is
the newline (`\n`) character. The complete implementation is shown below.

```c
  /* handle single-line comments */
"//"          BEGIN(sl_comment);
<sl_comment>[^\n]      /* eat up anything up to newline */
<sl_comment>\n        {
                        ++line_num;     // increment line number
                        BEGIN(INITIAL); // go back
                      }
```

This is a rough outline on how it looks in the final version (with a couple more additions).

## Handling modules

Again as the specification outlines we baked into `ptuc` apart from basic macro capabilities some rudimentary
module support. Our modules here only support *declarations* (of functions, variables etc) but *not* direct
statements. Modules are handled within `flex` and are passed to bison as part of the general source, that
means that bison *does not know* (at least directly) whether we switched our input buffer in order to parse
a module file.

Modules can have their own includes as well but up to a depth (default `10`); that's done to avoid
infinite-circular includes where we would include the same file over and over again. There are a couple
of interesting techniques illustrated here which are the following:

1) Multiple input (`flex`) buffers
2) Accurate line tracking (in includes and main source)
3) Error tracking with file insight

Let's explain how each one is implemented in our version.

### Multiple input (`flex`) buffers

When you want to switch the input to read another file than the one currently inside `yyin` `FILE` pointer you
should be probably use `flex`'s multiple input buffer capabilities. That functionality allows us to switch
our source file for reading at will as is outlined in the manual [here][5]. If you want something really basic
you can probably get away by letting `flex` manage your buffers for you, but if you want to do anything more
sophisticated you'll be probably out of luck with this method.

In our case since I wanted to support (somewhat) accurate error reporting, line tracking across files and
avoid any leaks in case we don't find the file to open or an error inside it. The key function prototypes
that we have to learn here are the following:

```c
YY_BUFFER_STATE yy_create_buffer(FILE *f, int size);    // creates a yylex buffer.
void yy_switch_to_buffer(YY_BUFFER_STATE new_buffer);   // switches to the pointed buffer.
void yy_delete_buffer(YY_BUFFER_STATE buffer);          // deletes an allocated buffer.
```

The outline is pretty simple, once we match the include `module` rule we open that file and read it
in-place. Again this happens without `bison` being directly aware of that, although functions that
report errors are. To avoid the infinite-circular include problems (which happens when a `module` includes
itself; hence it would do that over and over) we have imposed a *soft* include depth limit, which can be
changed with a command line argument (in the final version and the argument is `-d`).

Let's first check the rule that starts everything (start condition defined in the definitions and the actual rule
in the rule section).

```c
  /* include module starting condition */
%x incl_module
  /* later on in the rule section */

  /* handle module includes */
<incl_module>[ \t]*       {/* eat whitespaces */}
<incl_module>[^ \t\n]+{ID}    {
    if(include_file() == NULL)
      {yyerror("could not open include file");}
    else {
      if(verbose_flag) {
        fprintf(stderr, "\n --\n\tincluding module: %s\n --\n",
          yybuf_states[yylex_bufidx].fname);
      }
    }
    BEGIN(INITIAL);
  }
```

Here we have two rules that can be matched while satisfying the *exclusive* starting condition `<incl_module>`;
these serve two different purposes the first one eats up all the white-space or tab characters in order to get
to the `module` name which we expect to be match to an `ID`. Thus upon entering the second rule the value of
`yytext` would contain the actual name of the include module. The actual input redirection happens inside
`include_file` function which is shown below:

```c
/* include a file */
FILE *
include_file() {
  if(yylex_bufidx >= yystack_depth-1) {
    yyerror("yylex input buffer stack exhausted, current limit is: %d",
      yystack_depth);
    return NULL;
  }

  char *fname = template("%s.ptuc", yytext);
  if(fname == NULL) {return NULL;}
  /* assign the current include file pointer */
  FILE *fptr = fopen(fname, "r");
  /* return if we can't open */
  if(!fptr) {
    yyerror("lexical error: couldn't open %s module", yytext);
    free(fname);
    return NULL;
  }

  if(yybuf_states == NULL) {
    if((yybuf_states = calloc(yystack_depth,
          sizeof(*yybuf_states))) == NULL) {
      yyerror("\n -- Error: Could not allocate buffer stack");
      free(fname);
      return NULL;
    }
  }
  /* now save current state and set-up to switch to the next */
  yybuf_states[yylex_bufidx].state = YY_CURRENT_BUFFER;
  yylex_bufidx++;
  yybuf_states[yylex_bufidx].state = yy_create_buffer(fptr, YY_BUF_SIZE);
  yybuf_states[yylex_bufidx].fname = fname;
  yybuf_states[yylex_bufidx].incl_lnum = 1;
  /* switch the state */
  yy_switch_to_buffer(yybuf_states[yylex_bufidx].state);

  return fptr;
}
```

This function is comprised out of three main parts, which are the following:

1) Check if we can have an additional buffer (bounded by global variable `yystack_depth`)
2) Try to open the file pointed by `yytext` value after appending the `.ptuc` extension to it.
3) Save current state, advance global buffer index (`yylex_bufidx`) create state and populate it
4) finally switch to it.

It has to be noted that in order to represent a `flex` state we only need one variable of type `YY_BUFFER_STATE`
but since we require a bit of additional information in order to provide some additional functionality we have
created a wrapper structure for it which is the following:

```c
/* flex input buffers structure */
typedef struct __yybuf_state {
  YY_BUFFER_STATE state;  // flex buffer
  char *fname;            // filename we read from
  uint32_t incl_lnum;     // include file line no. tracker.
} yybuf_state;
```

The other two variables are used to store the *name* of the file we read from as well as the local
line counter for that file. After reaching to the end of the switched file an end of file character
 is matched (`<<EOF>>`) so naturally that would be the place to swap to a previous buffer (if any) or
 terminate our parser. Let's take a look at how we handle `<<EOF>>` when matched:

```c
<<EOF>>    {
               /* pop one of the stacked buffers, if any */
               if(!pop_delete_buffer()) {
                   if(yybuf_states)
                      {free(yybuf_states);}
                   flex_closure();
                   return EOF;
               }
           }
```

When we match an `<<EOF>>` we try to check if we have any more buffers, if we do we pop and delete the current
one using `pop_delete_buffer` function which also switches to the previous buffer to be processed; it also
returns `true` as long as we have more buffers to process. If we don't have any more buffers to process
that means we have completed reading out input in its entirety so we can terminate our parser and safely
return the `EOF` token -- which **is not the same** as `<<EOF>>`, the former is an actual `token` while
the latter is a character.

### Accurate line tracking

Since we have the ability to include multiple modules we are have a problem at hand with out starting stub
line counter implementation. Since our modules are read in-place by our lexer if we just used a single variable
to increment the line numbers we would report incorrect offsets as the end file is a stitched file of all the
inputs together, so we if had to include two files each of which were `20` lines. Then the total line counter would
be within `[1, 60]` which is wrong as if a problem was found at line `5` inside the second include file
the line reported would be `25` and not `5` (why?). This is fixed by wrapping inside our buffer data-structure
a separate line counter variable which serves that  purpose.

To keep track and report accurate line numbers we had to create functions in order to report and increment
the correct line number. The functions are the following:

```c
/* increment the line count, depending if we are including a file or not */
void
increment_line_count() {
  if(including_file())
    {yybuf_states[yylex_bufidx].incl_lnum++;}
  else
    {line_num++;}
}

/* fetch the line count, depending if we are including a file or not */
uint32_t
fetch_line_count() {
  return including_file() ?
    yybuf_states[yylex_bufidx].incl_lnum : line_num;
}
```

### Error tracking with file insight

A similar problem is faced when we want to report the name of the file in which the problem occurred. For this
purpose we again included another variable in our data-structure wrapper that holds the name of the file. The
function that returns that value is the following:

```c
/* fetch the currently processed file name */
char *
fetch_incl_name() {
  return including_file() ?
   yybuf_states[yylex_bufidx].fname : NULL;
}
```

## Handling junk

Discarding not significant characters is equally important as they might take up a significant percentage of our
input, thus we have to take care of that. Thankfully this is handled perfectly in our starting stub and only
small changes need to be made. We will briefly explain it though.


```c
[ \r\t]					{/* skip whitespace */}
\n 						{increment_line_count();}
<<EOF>>    {
               /* pop one of the stacked buffers, if any */
               if(!pop_delete_buffer()) {
                   if(yybuf_states)
                      {free(yybuf_states);}
                   flex_closure();
                   return EOF;
               }
           }

.        {yyerror("lexical error: unrecognized literal '%s'\n", yytext);}
```

The first rule matches and discards all white-space, return and tab characters. The second rule matches the
newline characters and increments the line counter variable. The third rule is responsible for handling the
end of file character (`<<EOF>>`) and finally the `.` rule matches anything else that was not matched already;
this is regarded as an error in our case, hence the call to `yyerror`.

# Epilogue

In this chapter we touched a bit on how to create your own language lexers and explained the techniques I
used in order to create my `ptuc` lexer. Hopefully this was helpful and of course I hope you poked both
the starting stub as well as the finished lexer quite a bit. The next part explains how to create
your own parsers using `bison` which is found [here][6].

[1]: https://en.wikipedia.org/wiki/Regular_expression#Examples
[2]: https://regex101.com/
[3]: ptuc_spec.md
[4]: https://github.com/andylamp/hashy_table
[5]: http://flex.sourceforge.net/manual/Multiple-Input-Buffers.html
[6]: ptuc_parser.md