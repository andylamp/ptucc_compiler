# Creating the parser for `ptuc`

In the final section of this two-part tutorial we will tackle the creation of our actual parser which checks
if our matched input tokens (coming from `flex`) are emitted in a syntactically correct order against our `ptuc`
specification. We will use `(gnu) bison` in order to create our parser and this implementation was tested
with versions of `bison >= 3.0.4`. Although `bison` originates from `yacc` it's a superset of its features
so I don't know if the code here is compatible with `yacc` -- I would assume that it isn't by default, but
I have not tested against it.

# Basic anatomy of a `bison` (`.y`) file

As with `flex`, `bison` has again a similar layout which is as follows:

```c
%{
    user code
%}
    bison declarations
%%
    bison grammar rules
%%
    more user code
```

# Bison user code

The code that resides here is copied *verbatim* in the resulting `.c` file; this might include custom libraries,
constants, includes and so on. Most includes and function prototype declarations happen at the top while their actual
definition happens at the bottom user code section.

# Bison stack types

`bison` `tokens` and `types` are allowed to have an accompanied value; that value can be used for emitting text or
treating it as a return value in order to do a specific task later on. If we need this functionality we have to tell
`bison` the type of that particular `tag` by declaring it inside a special `union` like this:

```c
%union
{
    char* tagA;
    double tagB;
}
```

This `union` tells `bison` that when we use a `token` or a `type` that is accompanied by `tagA` then we can use its value
like a normal `C` string literal; on the other hand if its accompanied by `tagB` then that value will be treated as a
`double` instead. It has to be noted that being a `union` and not a `struct` it also means the values use
*shared* memory and not separate segments as opposed to `struct` fields. We can have as many different tags as we
want inside the union and both `tokens` and `types` can have the *same* tag.

# Bison tokens

As we previously said in our `flex` part the `tokens` must be *firstly* defined in our parser so that we can
then generate the include `.tab.h` which we use in `flex`. Tokens are also called *terminal symbols* because
we cannot break them into simpler entities. Token declarations must be inside `bison`'s declaration
section. Additionally tokens can have "tags", which basically says to `bison` that this token can accompanied by
a particular value; hence a token definition has the following syntax:

```c
%token <tagA> TOK_NAME_A
%token <tagB> TOK_NAME_B
```

You can also group for convenience `tokens` that have the same `tag` inside the same declaration like so:

```c
%token <tagA> TOK_NAME_A TOK_NAME_C TOK_NAME_D
%token <tagB> TOK_NAME_B
```

The `tagB`, `tagB` *must* be defined inside the union which was described in the previous section. So using the `union`
shown in the previous section we can use inside rules `tagA` as a string while `tagB` as a `double`.

# Bison types

`bison` `types` are used to indicate that a `bison` state can have a return value, much like `tokens`. The same rules
apply but these have to be declared using a different directive like so:

```c
%type <tagA> TYPE_NAME_A
%type <tagB> TYPE_NAME_B
```

Again as with `tokens`, you can also group for convenience `types` that have the same `tag` inside the same declaration
like so:

```c
%type <tagA> TYPE_NAME_A
%type <tagC> TYPE_NAME_B TYPE_NAME_C TYPE_NAME_F
```

The `tags` are again defined inside the union as is the case with the `tags` used by `tokens` -- basically the same rules
apply here as well.

# Constructing grammar rules

In `bison` we create a *grammar* which syntactically evaluates if the `tokens` that `flex` generated are emitted in a
syntactically correct order. In order to do that we will have to take a good look at our language specification and break
it down to building blocks that we then have to express using `bison` rules. In `ptuc` abstractly we have a `program`
which can have `modules`, `declarations` and a `body` ending with a `dot`. This skeleton already gives us an
intuition of how to express our language in a rule.

Concretely the rule for our whole program is the following:

```c
program:
  incl_mods program_decl decls body KW_DOT
  ;
```

We see that the grammar rule `program` is satisfied if and only if `incl_mods`, `program_decl`, `decls`, `body` and
`KW_DOT` are satisfied in that *specific* order. In `bison` a rule is matched from *left-to-right* and all of the
sub-rules must be satisfied as well. So for this particular example the matching order is the following:

1. `incl_mods`
2. `program_decl`
3. `decls`
4. `body`
5. `KW_DOT`

These rules can be `tokens` or other grammar rules that have their own constraints, which as said previously have to be
satisfied as well -- think of it like a pre-order tree traversal. Grammar rules in general have the following syntax:

```c
rule_name:
    caseA
    | caseB
        .
        .
    | caseN
    ;
```
A rule starts by typing its *unique* name then a colon (`:`) followed by a number of cases which are separated
with a dash `|`; the last rule *must* be followed by a semicolon (`;`). Also rules don't have to be separated
by lines so this would be perfectly legal as well:

```c
rule_name: caseA | caseB | ... | caseN;
```

Additionally, grammar rules can have return values and (indirectly) take arguments. In order for a rule to return a
value of type `tag` it has to be declared in the stack type `union` and use the `type` directive to inform `bison` that
we expect that particular rule to return a value of type `tag`. With that in mind, let's go and show how to create a
simple rule.

## Simple rules

A simple rule, is one that comprises only our of *terminal symbols*... so an example of a simple rule would be one
that describes all of the scalar values in `ptuc`, so let's go ahead and implement it. By our language specification
([here][1]) we see that the *scalar* values are comprised out of the following:

* positive constant integers (`token`: `POSINT`)
* and real numbers (`token`: `REAL`)

So a rule that would match these is the following:

```c
scalar_vals:
      POSINT    {$$ = $1;}
      | REAL    {$$ = $1;}
      ;
```

A lot is happening here, but the main thing to note is that if `flex` returns to `bison`
either a `POSINT` or `REAL` `token` this rule will be matched, this `or` is indicated by
the dash (`|`) separating each case. The other important thing is that this particular rule
returns a value; this is indicated by the assignment of `$1` to `$$` as `$$` is a symbol that indicates
the return value of that rule (if any) and the `$1` indicates the value that accompanies the first
rule or `token`. Let's look at another example.

```c
// union entry
%union
{
    int add_tag;
}

// token entry
%token <add_tag> POSINT REAL
// type entry
%type <add_tag> pos_real_add

// actual rule
pos_real_add:
      POSINT REAL {$$ = $1 + $2;}
      ;
```

Assuming that this rule returns a double and both `POSINT` and `REAL` are accompanied by *numeric* arguments
then the above is perfectly valid. Please be *careful*, this rule is *only* matched if `POSINT` is *followed*
by a `REAL` `token` -- not the other way around. So if `flex` returns a `POSINT`, then a `REAL` this rule will
be matched and the resulting value would be the addition of the two.

## Complex rules

We talked above on how to construct really basic rules, now we will see how to create more complex rules --
which (normally) will comprise most of your real world grammars. I personally separate these rules into
two main categories, which are:

1. composition rules
2. lists (or recursive rules)

## Composition rules

Composition rules are basically rules that are composed from one or more rules (complex or simple). We have already
seen one such rule previously, which was:

```c
program:
  incl_mods program_decl decls body KW_DOT
  ;
```

This a composition rule as it has a case which is comprised out of *four* complex rules and one
terminal symbol (`KW_DOT`). Generally speaking a complex rule is one that has *at least one* case which
is composed with *at least one* non-terminal terminal symbol.

## Lists

Lists are a special composition rule type which is very interesting due to it property of letting us do
recursive matches. In order to understand this a bit better let's look at the definition of one such rule:

```c
/* identifiers (left recursion) */
ident_list:
    IDENT
    | ident_list KW_COMMA IDENT
    ;
```

Usually lists have two (2) cases, one that is responsible for the recursion and one handles the singular (terminal) case
of that rule. The recursion happens in the above example when we match the *second* case. That particular case allows us
to match the terminal symbols `KW_COMMA` and `IDENT` as well as ourselves -- so that essentially means that we can
`reduce` the terminal symbols and *re-enter* the same rule until we can match the first case which ends the recursion.

It has to be noted that there two types of recursion, *left* and *right*; the above rule we just showed is an example of
a *left recursion*. The same identical rule using *right recursion* would the be following:

```c
/* identifiers (right recursion) */
ident_list:
    IDENT
    | IDENT KW_COMMA ident_list
    ;
```

Although you have the option to use *right* instead of *left* recursion, due to how `bison` works internally you should
avoid that and opt to use only *left* recursion. That's because in the case of a *right* recursion in order to parse
that rule `bison` has to `shift` onto its stack all of the `tokens` that might be a potential match in the current
context for that rule without even applying it once (thus performing a `reduce` operation, which "eats up" the stack).

# Grammar conflicts

When parsing tokens `bison` tries to match them into one of the given grammar rules that can be potentially applied
in the current context. To do that `bison` supports two (2) basic operations, `shift` and `reduce`; `shift` means that
the `tokens` are *shifted* to the stack while `reduce` means that `tokens` are *consumed* from the stack. Depending on
how you have created your rules you might have introduced *ambiguities* in the grammar; this means that `bison` in
*at least one* occasion does not know *precisely* which *singular* rule to apply. This creates a *conflict*, which
`bison` (thankfully) reports at compile time as a warning. There can be two (2) different types of conflicts:

* shift/reduce
* reduce/reduce

## Shift/Reduce conflicts

This type of conflict happens when `bison` does not know which operation to perform, `shift` or `reduce`. An example
of such rule would the following:

```c
/* identifiers */
ident_list:
    IDENT
    | IDENT KW_COMMA
    | ident_list KW_COMMA IDENT
    ;
```

The introduction of this second case, creates an *ambiguity* in our grammar which in turn creates a *shift/reduce*
conflict. In order to better understand that we have to explain a bit more how `bison` parses the `tokens` and
selects to either `shift` or `reduce`. As `bison` parses the `tokens` even if it matches a rule it does not immediately
`reduce`, even if a rule is matched; what instead happens is that `bison` always has stored one `token` ahead to a
special variable called the **lookahead** `token`. The value of the lookahead token is stored in `yychar` and (if any)
its semantic value and its location in `yylval` and `yylloc` respectively.

Now in our case when we parse the `IDENT` token and we have in our *lookahead* `token` the `KW_COMMA`, we can either
use the second case and `reduce` or use the third rule and `shift` as we can match the first two parts of the third case.
This would happen if we matched `IDENT` as `ident_list`, `reduced` it using the first case and `shifted` the result,
then matched the `KW_COMMA` and we would expect an `IDENT` in order to complete the rule. Normally *shift/reduce*
conflicts should be resolved and this can be done by either specifying precedence (will be discussed later) or
altering your grammar.

## Reduce/Reduce conflicts

This type of conflict is more serious than the previous one as `bison` knows that is has to perform a `reduce`
operation but has *more than one* way of doing so -- this very bad and indicates a serious problem in the grammar. An
example of that rule would be the following:

```c

/* identifiers */
ident_list:
    %empty
    | IDENT
    | ident_list KW_COMMA IDENT
    ;

/* data-types using no cast */
cdata:
      %empty
      | KW_BOOLEAN
      | KW_CHAR
      | KW_INTEGER
      | KW_REAL
      ;

/* combine them */
combs:
    %empty
    | combs ident_list;
    | combs cdata;
```

Now  in the above segment we have a serious issue; let's assume that we have to parse an empty input, if we try to
match it using the above rules we can see that is can be reduced in multiple ways; thus `bison` does not know reliably
which  rule to use in order to `reduce`, hence the conflicts. This can be resolved as with *shift/reduce* conflicts by
altering the grammar itself or using precedence rules, which will be discussed later on.

## Expected conflicts

In some grammar it is normal to have a small amount of *shift/reduce* conflicts (but no *reduce/reduce* conflicts); in
order to indicate that this is normal and suppress the warnings generated by `bison` upon compilation one can use the
`%expect` directive. This is placed inside the `bison` declaration section and takes an argument of the precise amount of
*shift/reduce* conflicts that we are expecting, like so:

```c
%expect n
```

If the number of *shift/reduce* conflicts is not equal to `n` (less or more) or we have a *reduce/reduce conflicts an
error is thrown and compilation is stopped.

# Precedence rules

Precedence is a really important aspect of your grammar; that is... if you want to do something meaningful with it you
are bound to be affected by it. Let's first show an example; suppose that  we have to add three numbers `a`, `b` and
`c` (`a` + `b` + `c`). Now also suppose that we have the following grammar rule for addition:

 ```c
 add_op:
    num `+` num
    ;
 ```

 This rule expects two numbers and a plus sign (`+`) between them, but upon parsing the input we have the following:

 ```
 num1 -> `+` -> num2 -> `+` -> num3
 ```

 This would create a *shift/reduce* conflict as bison does not now how to **precisely** parse the input as there
 is more than one way of parsing the tokens received. This is because we can either parse the input as:

```c
(num1 `+` num2) `+` num3
```

Which would result in the following operations from `bison`:

1. `(num1 + num2)` match
2. reduce using `add_op`
3. shift result
4. `(res1_2 + num3)` match
5. reduce using `add_op`
6. shift result

On the other hand, we could also parse it like this (perfectly legal) way:

```c
num1 `+` (num2 `+` num3)
```

Which would result in the following operations from `bison`:

1. `(num2 + num3)` match
2. reduce using `add_op`
3. shift result
4. `(num1 + res2_3)` match
5. reduce using `add_op`
6. shift result

The first example is how we parse the expression using *left* operator associativity while the second case shows how
we would parse the expression using *right* associativity. The actual problem lies when we have more than one operators
to process in sequence as `bison` does not know if it should reduce or shift; by default `bison` elects to
*shift* instead of reduce.


There are *four* (4) types of precedence types in `bison` three (3) of which declare both precedence as
well as associativity while the last (as its name suggests) declares only precedence. The complete list is
the following:

* left (`%left`): Indicates that this operator has *left* associativity (e.g. (a + b) + c is preferred)
    * syntax is: `%left symbols`
* right (`%right`): Indicates that this operator has *right* associativity (e.g. a + (b + c) is preferred)
    * syntax is: `%right symbols`
* nonassoc (`%nonassoc`): Indicates that this operator cannot be seen in sequence and is considered a *syntax error*
if that's encountered (e.g. a + b + c would throw an error).
    * syntax is: `%nonassoc symbols`
* precedence (`%precedence`): Indicates just precedence **not** associativity.

In the previous cases, precedence did not actually affect the result but there are some cases that
precedence *does* affect the result; one such example is if we had the following expression:

```c
a * b + c
```

Here we don't have precedence for sequential operations using the same operator but different ones; again if no
precedence is set for the multiplication (`*`) and addition (`+`) operators, `bison` would not be certain which
operation to perform first, `a * b` or `b + c` and a shift/reduce conflict would again occur. Of course we
can easily see that doing `(a * b) + c` is **not** the same as `a * (b + c)`. This is solved by determining the
precedence of the *operator itself against the others*. This actually took me quite a while to figure out as I did not
spot it right away when reading the documentation.

When declaring precedence groups the group with the **higher line number** has **greater** precedence than
the previous ones. It's also good practice to group operator of equal precedence in the same declaration.
As a final example, the complete precedence rule list for `ptuc` follows.

```c
%left KW_SEMICOLON

/* Class 8 prec. group */
%left KW_OP_OR KW_OR

/* Class 7 prec. group */
%left KW_OP_AND KW_AND

/* Class 6 prec. group */
%left KW_EQ KW_DIFF KW_LESS_EQ KW_LESS KW_GREATER_EQ KW_GREATER

/* Class 5 prec. group */
%left KW_OP_PLUS KW_OP_MINUS

/* Class 4 prec. group */
%left KW_OP_MUL KW_OP_DIV KW_DIV KW_MOD

/* Class 3 prec. group (for casting) */
%right TYPE_CAST_PREC

/* Class 2 prec. group */
%right UNARY_PREC

/* Class 1 prec. group (highest precedence) */
%right KW_NOT KW_OP_NOT

/* dangling else lookalikes */
%precedence IF_THEN
%precedence KW_ELSE
```

## Non-operator precedence

Again, sharp readers will see notice in the above code something that I have yet to explain; and  they'd be right! As I
left that for last. Notice that there is no `token` defined for `IF_THEN` or `TYPE_CASE_PREC`, so it turns out that one
can declare precedence for arbitrary symbols and use the term `%prec` to enforce that precedence into a rule, like so:

 ```c
 add_op:
    num `+` num %prec IF_THEN
    ;
 ```

So using the `add_op` rule we can modify it as follows to *enforce* that particular rule to have the precedence (and
associativity) of `IF_THEN` or any other symbol. These can be used to also enforce precedence in order to resolve
conflicts in our grammar, by using our previous example that created a *shift/reduce* conflict:

```c
/* in decl. section */
%precedence lower
%precedence higher

/* identifiers */
ident_list:
    IDENT
    | IDENT KW_COMMA                %prec higher
    | ident_list KW_COMMA IDENT     %prec lower
    ;
```

Since `higher` is declared lower than `lower` it has **higher** precedence, thus by using `%prec` directive we enforce
that precedence in our rules, solving the previous ambiguity that was present in our grammar by always favoring the
second case. This technique can also be used for resolving *reduce/reduce* conflicts as well. The reasoning behind the
precedence specification for non-token symbols `IF_THEN` and `TYPE_CASE_PREC` will be explained when we tackle our
`ptuc` grammar implementation.

# Freeing symbols

This is a *very* important topic as if you want to produce an AST (Abstract Syntax Tree) you'd probably
allocate some memory to do that; in languages like `C` or `C++` if you dynamically allocate memory you have
to free it yourself; `bison` has no reasonable obligation to clean-up your mess, that's your job.

Unfortunately most parsers I've seen that allocate memory assume that since that's done inside `bison` itself somehow
they expect that `bison` (or `flex`) will take care of that but unfortunately that's not the case. Let's look an
example that would produce a definite *memory-leak* in our program. We will use the above rule we created using the
`POSINT` and `REAL` `tokens`; inside flex they have the return the following when they are matched:

```c
{SNUMBER}   {
                yylval.crepr = strdup(yytext);
                return POSINT;
            }

{REAL}      {
                yylval.crepr = strdup(yytext);
                return REAL;
            }
```

The line `yylval.crepr = strdup(yytext);` means that we *copy* the value of `yytext` into the `yylval.crepr`
(which is a `tag` in our `bison` `%union { ... }`). This means that both of these `tokens` are accompanied by a
*dynamically* allocated vale stored in their `tag`. Hence in the following rule:

```c
// our union decl.
%union
{
    char* crepr;
}

// later on...
pos_real_add:
      POSINT REAL {$$ = strtol($1, NULL, 10) + strtol($2, NULL, 10);}
      ;
```

The `$1` and `$2` contain the values of `POSINT` and `REAL` respectively. The rule does its job (after first
converting them to actual numbers using `strtol` function), which is to add the two and return their result by
assigning it to `$$` -- there is a catch however. After the rule finishes (returns the `$$`) memory for
`$1` and `$2` is not free'ed at any point, as after the calls to `strtol` they are not used anymore; thus they create
a definite *memory-leak*. The correct way to handle *dynamically* allocated symbols or `tags` is to free them as soon as
we have no use for them -- which is this case is after the calls to `strtol`; hence a correct implementation that does
not create any leaks would be the following:

```c
// our different union
%union
{
    char* crepr;
    double val;
}

// token and types
%token <crepr> POSINT REAL
%type <val> pos_real_add


// later on.
pos_real_add:
      POSINT REAL {$$ = strtol($1, NULL, 10) + strtol($2, NULL, 10); free($1); free($2);}
      ;
```

Now let's look at yet another example of where handling these `free`'s isn't that obvious.

```c
// assume that above we had: %type <crepr> pos_int_num and %type <val> pos_add
pos_int_num:
    POSINT {$$ = $1; free($1);}
    ;

pos_add:
    POSINT `+' POSINT {$$ = strtol($1, NULL, 10) + strtol($3, NULL, 10); free($1); free($3);}
    ;
```

Here we have two rules, one that recognizes `POSINT`'s and one that simply performs an addition if the output is a
`POSINT` followed by a plus sign (`+`) and another `POSINT`. Notice that that we should `free` up the values right after
we are finished with them, so naturally one would say that in the `pos_int_num` rule we are
done with the value of `POSINT` so we should free it. That's *incorrect* and would most likely cause a
*segmentation-fault*; this is the case because the value of `$$` points to that particular string, since we assign `$$`
to be equal with `$1` -- but `$1` is a pointer to the string. Thus the value of `$$` for each `POSINT` is the actual
value that `$1` and `$3` will have in the `pos_add` rule; so if we free it there when `strtol` tries to use that
will most likely fail -- not to mention that free will attempt to free an already free'ed location. The correct way of
handling the above scenario would be the one below:

```c
// assume that above we had: %type <crepr> pos_int_num and %type <val> pos_add
pos_int_num:
    POSINT {$$ = $1;}
    ;

pos_add:
    POSINT `+' POSINT {$$ = strtol($1, NULL, 10) + strtol($3, NULL, 10); free($1); free($3);}
    ;
```

Sharp readers will immediately spot that the above segments regardless of the tips provided would be quite prone to
double-free, or invalid-free errors and they would be perfectly right. This is why when dealing with such issues I have
constructed a wrapper function in order to take care of these issues -- but it requires the user to obey a few simple
rules. Let's illustrate the function first and then explain how it actually works.

```c
/*  handy clean-up function */
void
tf(char *s)
  {if(s != NULL && strcmp(s, "") != 0) {free(s);}}
```

This is simple but *very* effective because we can call it freely on any symbol that we might want to free, even those
that have already being released. This is done through the first `if` that checks if `s` is `NULL` or equal to `""`.
The first is straightforward as that checks if `s` is a valid pointer while the second one is a bit weird at first;
why check for that particular value you might ask? This is simple, we use that value to indicate that we have an
empty string or a symbol that might not have a value inside that rule. Thus the rule is that we **always**
expect `s` to be a *pointer* and have a value of `NULL` or `""` at any given point that we *don't* want to call
`free` on that particular symbol. It's pretty neat and works quite well in practice (and doesn't clutter the
codebase as well!).


# Destructors

Another thing that important (that is neglected quite often I am afraid) is how to handle things when
something goes bad during parsing -- and oh boy in compilers isn't that usual. Thankfully `bison` has the ability
to clean its own stuff when something does go wrong -- but what about *our* dynamically allocated symbols. Thankfully,
`bison` has a facility that can help us free-up own resources by calling a `destructor` on each of the discarded
symbols -- but what does `bison` consider as a *discarded symbol*? The following list is mostly an
extract from `bison`'s manual which defines that `bison` considers as *discarded symbols*.

Valid *discarded symbols* are the symbols that fall into *at least* one of the following categories:

* stacked symbols popped during the first phase of error recovery
* incoming terminals during the second phase of error recovery
* the current lookahead and the entire stack (except the current right-hand side symbols) in the case the parser is
*fail-fast*
* the current lookahead and the entire stack (including the current right-hand side symbols) when the `C++` parser
catches an exception in `parse`
* the start symbol when the parser succeeds

Additionally, `bison` only calls the destructors for *user-defined* symbols. If you call a destructor for a
`tag`-less `type` or `token` when their destructor expects one to be present a warning notifying the user of
that fact should pop during compilation. One such example is when you use the `<*>` as a `tag`,
which indicates that *all* of your `tokens`, `types` are expected to return a value. Let's first look at the
destructor syntax:

```c
%destructor { /* C code */ } symbol_list
```

The destructor is placed into the *declaration* section of the bison file and between the brackets `{`, `}` any valid
`C` or `C++` code can be entered followed by a list of symbols that this destructor should be executed for. So this
would be a perfectly legal destructor for the `crepr` tag:

```c
%destructor { tf($$); } <crepr>
```

Destructors have the ability to be executed on a *per-tag* basis or globally; that means we can assign different
destructors for different `tags`. That's the case because some `tags` might have different `types` declared for
them inside the `union`, hence a different way of freeing them might be required. For our needs and purposes the
above destructor will suffice, but for reference here are a couple more valid examples:

```c
%union
{
    void *aptr;
    char* crepr;
}

/* destructor specific for <crepr> tag */
%destructor { tf($$); } <crepr>
/* destructor specific for <a> tag */
%destructor { if(a) {free(a);}; } <a>
%destructor { /* any tag destructor */ } <*>
%destructor { /* tagless symbol destructor */ } <>
```

Notice the `tag`-less destructor, which is called on every symbol that is present. This might raise the question
on how to select which destructor to call since there might be more than one. Should `bison` detects that there is
a `tag`-specific destructor for a discarded symbol it will call that and ignore the more generic one, so in case
of discarding a symbol that has a semantic value of `<crepr>` then only the destructor for `<crepr>` will be called.


# Error recovery

In case we encounter a lexer (`flex`) or parser (`bison`) error under default conditions our parser will terminate
after seeing the first error -- these are called *fail-fast* parsers, but nobody actually wants them... (except maybe
lazy students). This means that if our input has more than one mistake we would only detect the first and exit! This
process would get quite tedious as repeated compilations would be required in order to detect and fix all errors instead
of reporting all errors in our source at the first parse.

Thankfully `bison` has error recovery capabilities! They are also quire simple to define and explain but require a
lot of skill, practice and a hellish insight in order to be used correctly. Say for example that we have the following
rule:

```c
program_decl:
    KW_PROGRAM IDENT KW_SEMICOLON
    ;
```

What if an error was encountered inside that rule, say for example we had a *valid* `KW_PROGRAM` token as well as
an `IDENT` but not a semicolon (`;`); then if we didn't have error recovering capabilities our parser would end as we
previously said.

In order to allow `bison` to recover from a syntax error we have to create a rule that recognizes a *special* `bison`
`token` called `error`. It is defined by default and there is no need to explicitly define it. Thus the above rule
would be modified as follows in order to allow for error recovery:

```c
program_decl:
    KW_PROGRAM IDENT KW_SEMICOLON
    | error KW_SEMICOLON
    ;
```

The above addition does a couple of things, firstly if we detect an error then we will immediately switch to the
second (and error handling) case and secondly we will **ignore** and **discard** everything encountered up the
*next* semicolon (`;`). This switch happens by discarding both the value of the current semantic tags in current
context (if any) as we as all the tokens on the `bison` stack until we reach a point where the rule which contains
the `error` token is acceptable -- in our case this happens when we encounter the *next* semicolon (`;`). Of course
for all of the discarded symbols the appropriate destructors will be run as well, if any.

Additionally, after encountering an error it's likely that this fact will then create much more consecutive errors; to
 avoid this console spam `bison` *suppresses* error messages until *three* (3) consecutive `tokens` have been parsed
 and shifted successfully. If you don't like (or want) this behavior by default you can put the `yyerrok`
 inside the `error` rule like so:

```c
program_decl:
    KW_PROGRAM IDENT KW_SEMICOLON
    | error KW_SEMICOLON { yyerrok; }
    ;
```

Later on when defining our `ptuc` grammar we will give insights regarding the places we elected to put our error
recovering states.

# Creating `ptuc` grammar

In this section I will briefly describe `ptuc` grammar rules and how they are structured while also touching in greater
detail some implementation related topics that I find to be quite intriguing. As a general rule you should first
understand the grammar you want to create rules for and that's really important (`ptuc` spec. ref. [here][1]); as if you
"get-it" then translating these rules into a working grammar should be quite easy. This section will follow the natural
structure of the grammar, defining small primitives and using them to build our grammar.

## Primitives

Primitives are the building blocks that we will use in order to create more complex rules; in this category I included
 the following language elements:

* strings
* scalar/boolean values
* data-types
* identifiers
* expressions
* statements

The first three are simple rules to implement as well as understand, things start to get a little bit tricky when
dealing with statements and expressions. Most rules *return* a value, and in this language we only have one type,
`<crepr>` that's of type `char *`; so all of the return values are assumed to be of that type. Also please be aware that
we *only* copy values when we *have to do so*, otherwise we just *pass* the pointer for the already allocated value to
the return value (`$$`). If in doubt, look at the complete source ([ptucc_parser.y][3]).

### Strings

Strings are using a very simple rule that just groups the terminal symbols for the two types of strings `ptuc` supports.
The only catch is that when we have a *single* quoted string we change the *single* quotes to *double* using
`string_ptuc2c` function defined in `cgen.c`.

```c
/* string values */
string_vals:
      STR_LIT   {$$ = $1;}
      | STRING	{$$ = string_ptuc2c($1);}
      ;
```

### Scalar/Boolean values

Scalar values rule is again very simple and similar to strings:

```c
scalar_vals:
      POSINT    {$$ = $1;}
      | REAL    {$$ = $1;}
      ;
```

Boolean values are the same as well, but here we don't just pass the accompanied value as the output but rather we
use `strdup` to copy the string `"true"` or `"false"` to the output.

```c
bool_vals:
      KW_BOOL_TRUE    {$$ = strdup("true");}
      | KW_BOOL_FALSE {$$ = strdup("false");}
      ;
```

Then both of these are joined into a complex rule that can describe both in one go:

```c
/* scalar/bool values */
lit_vals:
      scalar_vals {$$ = $1;}
      | bool_vals {$$ = $1;}
      ;
```

### Data-types

The data-types here are just a collection of the available ones that `ptuc` has **without** the custom types.

```c
/* data-types using no cast */
cdata:
      KW_BOOLEAN {$$ = "bool";}
      | KW_CHAR {$$ = "char";}
      | KW_INTEGER {$$ = "int";}
      | KW_REAL {$$ = "double";}
      ;
```

Here we compose a data-type rule that has all of the default ones and can also accept any custom ones that are treated as
an identifier (`IDENT`).

```c
/* data-types that might use cast to type */
cdata_with_type:
      cdata     {$$ = strdup($1);}
      | IDENT   {$$ = $1;}
      ;
```

Notice here that in the case of `cdata` we *have* to copy the string due to the fact that they were statically allocated
inside the `cadata` rule.

#### Type cast

In `ptuc` we support type casting, that is we can cast one type into another; this is done in the same way as
it's done in `C`. Additionally we also support infinite nesting, so we allow `((((type)))) var_to_cast` as well as
`(type) var_to_cast`, they are treated as equivalents. To allow this we use *recursion*, the first case recursively
strips away the surplus parenthesis pairs up to the point we reach one pair and one type. The `template` function here
is used to return a formatted string and performs a dynamic allocation, thus we have to free up the resources using
`tf`.

```c
/* expression that we use to allow casting with inf. nested pars */
type_cast:
      KW_LPAR type_cast KW_RPAR
        {$$ = template("(%s)", $2); tf($2);}
      | KW_LPAR cdata_with_type KW_RPAR
        {$$ = template("(%s)", $2); tf($2);}
      ;
```

### Identifiers

Previously we talked about identifiers, so here is the rule that implements them, which basically joins the terminal
case along with a second case that allows us to recursively parse more than one identifiers separated by commas (`,`):

```c
/* identifiers */
ident_list:
        IDENT {$$ = $1;}
        | ident_list KW_COMMA IDENT
          {$$ = template("%s, %s", $1, $3); tf($1); tf($3);}
        ;
```

Another important identifier rule is the one we have to use for arrays as they are followed by a number of brackets
equal to the number of their dimension, so a 3-dimensional array like: `array[2][3][4]` is followed by three
bracket pairs; in our rule this is represented in the `brackets_list` rule that is also shown below.

```c
/* this is to allow ident[index] scheme */
ident_with_bracket:
        IDENT   {$$ = $1;}
        | IDENT brackets_list
            {$$ = template("%s%s", $1, $2); tf($1); tf($2);}
        ;
/*
  handle variable array size, eat up brackets in a
  padding fashion e.g. [] -> [][] -> [][][] ...
*/
brackets_list:
      KW_LBRA POSINT KW_RBRA
        {$$ = template("[%s]", $2); tf($2);}
      | brackets_list KW_LBRA POSINT KW_RBRA
        {$$ = template("%s[%s]", $1, $3); tf($1); tf($3);}
      ;

```

### Expressions

Inside expression we group the three types of expressions we have one-side expressions such as `!ident`, or `+1` and
two-side expressions such as `a + b`, `b % c` etc. We intuitively composed them into a rule that follows:

```c
expression:
    one_side_exp    {$$ = $1;}
    | two_side_exp  {$$ = $1;}
    ;
```

Additionally we consider as expressions also strings, literal values, function calls and so on... so another rule was
created to accommodate that:

```c
basic_exp:
          type_cast exp_join %prec TYPE_CAST_PREC
            {$$ = template("%s %s", $1, $2); tf($1); tf($2); }
          | KW_LPAR basic_exp KW_RPAR {$$ = template("(%s)", $2); tf($2);}
          | proc_call
            {$$ = $1;}
          | lit_vals
            {$$ = $1;}
          | string_vals
            {$$ = $1;}
          | expression
            {$$ = $1;}
          ;
```

The important part is that we use *precedence* here to indicate that the first case, where we match and `reduce` in
case we have a type-cast and an expression using the `%prec` directive we enforce the precedence and associativity
of `TYPE_CAST_PREC` overriding the the `bison` inferred precedence; this eliminates a potential ambiguity in our
grammar as if we did not enforce that precedence rule `bison` would not be certain whether to `shift` using the first
case or `reduce` using the second case.

The final step is to describe `exp_join` state, which is the following:

```c
exp_join:
    ident_with_bracket  {$$ = $1;}
    | basic_exp         {$$ = $1;}
    ;
```

This is a clever way to pack the identifiers that are followed with an array without causing any ambiguities
in our grammar.

### Statements

Statements form the block of our logic, they contain most useful building blocks, that are really not all that
interesting in their implementation, just a straight up translation of the rules in the spec. into tokens, then all
of them are composed into the complex rule that follows:

```c
statement:
    common_stmt     {$$ = $1;}
    | proc_call     {$$ = template("%s;\n", $1); tf($1);}
    | while_stmt    {$$ = $1;}
    | for_stmt      {$$ = $1;}
    | if_stmt       {$$ = $1;}
    | label_stmt    {$$ = $1;}
    | ret_stmt      {$$ = $1;}
    | body          {$$ = $1;}
    ;
```

Then we can define the following two rules, which allows us to parse a lot of statements using recursion while also
handling empty input correctly.

```c
statements:
    {$$ = "";}
    | statement_list  { $$ = $1; }
    ;

statement_list:
    statement
    | statement_list KW_SEMICOLON statement
        { $$ = template("%s%s", $1, $3); tf($1); tf($3); }
    ;
```

## Command enclosure (body)

Our command enclosure (body) is comprised out of zero or many statements, these include assignments, function/procedure calls
and so on. The rule is simple, as the statements are expanded into their respective rules. The `body` rule is the following:

```c
body:
    KW_BEGIN statements KW_END
        {$$ = template("{%s}", $2); tf($2);}
    | KW_BEGIN error KW_END
        {$$ = "";}
    ;
```

This is handy as we can use it in all places where we want to have multiple statements, like inside `if`, `while`
statements, function/procedure definitions, modules and so on. There is a catch though, in `functions` we have to use a
different body rule as they require to support the `result` keyword, this happens by just using the same structure
albeit using the special statements rule we introduced for functions above. The resulting rule follows.

```c
func_body:
    KW_BEGIN func_stmts KW_END
        {$$ = template("{%s}", $2); tf($2);}
    | KW_BEGIN error KW_END
        {$$ = "";}
    ;
```

## Modules

Modules (as we previously said in our lexer [here][4]) are stitched to the input so `bison` has no idea that we are
reading from another file; thus we just see a `token` sequence. From our spec. inside our modules we *only* allow
declarations of variables, functions and so on thus inside `incl_mod` we make sure that happens, if not an error is
thrown. The 'incl_mods' rule allows us to parse multiple modules while also handling empty input correctly.

```c
incl_mods:
      {$$ = "";}
      | incl_mods incl_mod KW_SEMICOLON
        {$$ = template("%s\n%s", $1, $2); tf($1); tf($2);}
      ;

incl_mod:
      KW_MODULE IDENT incl_mods KW_BEGIN decls KW_END KW_DOT
      {
        $$ = template("// included module %s\n%s\n%s", $2, $3, $5);
        tf($2); tf($3); tf($5);
      }
      | error KW_SEMICOLON {$$ = "";};
      ;
```

## Program header

This is a very simple rule, it just checks if the program header is aligned with the rules in our spec., if not the
second case is matched and an error is reported.

```c
program_decl:
    KW_PROGRAM IDENT KW_SEMICOLON  	{ $$ = $2; }
    | error KW_SEMICOLON {$$ = "";}
    ;
```

## Program declarations

This rule allows us to declare variables, functions/procedures and custom data-types; we can declare none or many of
each and at any order -- gotta love recursive rules :).

```c
/* flexible decls allow in any order variable, type, function decls */
decls:
      /* in case of no decls */
      {$$ = "";}
      | decls error KW_SEMICOLON {$$ = $1;}
      | decls type_decl
        {$$ = template("%s\n%s", $1, $2); tf($1); tf($2);}
      | decls var_decl
        {$$ = template("%s\n%s", $1, $2); tf($1); tf($2);}
      | decls func_decl
        {$$ = template("%s\n%s", $1, $2); tf($1); tf($2);}
      | decls proc_decl
        {$$ = template("%s\n%s", $1, $2); tf($1); tf($2);}
      ;
```

### Variables

```c
/* variables */
var_decl:
        KW_VAR var_decl_list
          { $$ = template("%s\n", $2); tf($2); }
        ;

var_decl_list:
        var_decl_single {$$ = $1;}
        | var_decl_list var_decl_single
          {$$ = template("%s\n%s", $1, $2); tf($1); tf($2);}
        ;
```

### Procedures

Procedures are like our main `body`, albeit they take arguments.

```c
/* proc. decl. */
proc_decl:
    KW_PROCEDURE IDENT
        KW_LPAR type_only_arguments KW_RPAR KW_SEMICOLON
        decls body KW_SEMICOLON
        {
            $$ = template("void %s(%s) {\n%s\n%s}\n",
                $2, $4, $7, $8);
            tf($2); tf($4); tf($7); tf($8);
        }
    ;
```

### Functions

```c
/* function-decl. */
func_decl:
    KW_FUNCTION IDENT
        KW_LPAR type_only_arguments KW_RPAR
        KW_COLON cdata_with_type KW_SEMICOLON
        decls func_body KW_SEMICOLON
        {
            $$ = template("%s %s(%s) {%s result;\n%s\n%s\nreturn result;}\n",
                $7, $2, $4, $7, $9, $10);
            tf($2); tf($4); tf($7); tf($9); tf($10);
        }
    ;
```

# Special `bison` commands

Here is a simple summary of the `bison` special commands and a brief description on
what they do -- a *cheat-sheet* if you'd like to call it that.

* `%union`: indicates the available `tags` and their types.
* `%token`: a numerical value that indicates a specific input is matched -- they originate usually from `flex`.
* `%type`: is used to indicate that a `bison` state returns a value.
* `%right`: used to indicate *right* precedence (e.g. a + b + c -> a + (b + c)).
* `%left`: used to indicate *left* precedence (e.g. a + b + c -> (a + b) + c).
* `%nonassoc`: used to indicate that the operators are *not-associated* and using it like so would indicate a syntax error.
* `%start`: used to indicate our starting rule (or you could call it state as well).
* `%expect`: used to indicate that we *expect* our grammar to have a specific number of *shift/reduce* conflicts
(**not** *reduce/reduce* conflicts). If the number of errors differ, then a compilation error is
thrown (e.g. `%expect n` if *shift/reduce* count is not *exactly* `n`, we fail to compile).
* `%pure_parser`: used to indicate that we *want* our parser to be a reentrant; this means that it will not use global
variables to communicate with `flex`. This option is useful when we want to create a thread-safe parser.
* `%raw`: this is to enable `token` compatibility with `yacc`; `yacc` starts numbering multi-character `tokens`
sequentially from `257` while `bison` normally starts from `3`. Single character `tokens` in `yacc` use their ANSI value.
* `%no_lines`: this option doesn't inform the `C` compiler regarding the line numbering scheme (thus they don't
generate the `#lines` pre-processor commands). Don't turn this off, as that enables to map your source code to the
resulting `.c` file produced by `bison`; this helps debugging a lot.
* `%token_table`: this generates an array of `token` names in the parser file. The generated array is named `yytname` and
each `token` name is located as `yytname[i]` where `i` is the number `bison` has assigned to that `token`. Along with the
 table `bison` generates some macros that are provide some useful information, these are:
  * `YYNTOKENS`: Returns the number of defined `tokens` plus one (for the `EOF`).
  * `YYNNTS`: Returns the number of *non-terminal* symbols (basically is the number of `tokens`).
  * `YYNRULES`: Returns the number of grammar rules.
  * `YYNSTATES`: Returns the number of (generated) parser states.
* `%define`: allows us to tweak some parser parameters by defining some configuration properties (more [here][2]);
the most common would be: `%define parse.error verbose` that enables more verbose syntax error information output.


# Epilogue

I had a blast creating this project and writing this guide. Due to my recent dabblings I don't get to play much with
these tools so it was a nice escape. Hopefully you learned something through all of this ;).

[1]: ptuc_spec.md
[2]: http://www.gnu.org/software/bison/manual/html_node/_0025define-Summary.html
[3]: ../ptucc_parser.y
[4]: ptuc_lexer.md