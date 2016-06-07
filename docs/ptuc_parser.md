# Creating the parser for `ptuc`

In the final section of this two-part tutorial we will tackle the creation of our actual parser which checks
if our matched input tokens (coming from `flex`) are in a syntactically correct order against our `ptuc`
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

The code that resides here is copied *verbatim* in the resulting `.c` file; this might include custom libraries, constants, includes and so on.
Most includes and function prototype declarations happen at the top while their actual definition happens at the bottom user code section.

# Bison stack types

`bison` `tokens` and `types` are allowed to have an accompanied value; that value can be used for emitting text or treating it
as a return value in order to do a specific task later on. If we need this functionality we have to tell `bison` the type of
that particular `tag` by declaring it inside a special `union` like this:

```c
%union
{
    char* tagA;
    double tagB;
}
```

This `union` tells `bison` that when we use a `token` or a `type` that is accompanied by `tagA` tag then we can use its value
like a normal `C` string literal; on the other hand if its accompanied by a `tagB` tag then that value will be treated as a
`double`. It has to be noted that being a `union` and not a `struct` it also means the values use *shared* memory and not
separate segments as opposed to `struct` fields. We can have as many different tags as we want inside the union and both
`tokens` and `types` can have the *same* tag.

# Bison tokens

As we previously said in our `flex` part the `tokens` must be *firstly* defined in our parser so that we can
then generate the include `.tab.h` which we use in `flex`. Token definitions must be inside `bison`'s declaration
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

`bison` `types` are used to indicate that a `bison` state can have a return value, much like `tokens`. The same rules apply
but these have to be declared using a different directive like so:

```c
%type <tagA> TYPE_NAME_A
%type <tagB> TYPE_NAME_B
```

Again as with `tokens`, you can also group for convenience `types` that have the same `tag` inside the same declaration like so:

```c
%type <tagA> TYPE_NAME_A
%type <tagC> TYPE_NAME_B TYPE_NAME_C TYPE_NAME_F
```

The `tags` are again defined inside the union as is the case with the `tags` used by `tokens` -- basically the same rules apply here as well.

# Constructing grammar rules

In `bison` we create a *grammar* which syntactically evaluates if the `tokens` that `flex` generated are syntactically correct -- or to put it more simply, the order they are
emitted is allowed by our *grammar*. In order to do that we will have to take a good look at our language specification and break it down to some building blocks that we then
have to express. In `ptuc` we have a `program` which can have `modules`, `declarations` and a `body` ending with a `dot`. This skeleton already gives us an intuition of how
to express our language in a rule.

Concretely the rule for our whole program is the following:

```c
program:
  incl_mods program_decl decls body KW_DOT
  ;
```

We see that the `grammar` rule program is satisfied by `incl_mods`, `program_decl`, `decls`, `body` and `KW_DOT` are
satisfied in that order. In `bison` a rule is matched from *left-to-right* and all of the sub-rules must be satisfied as well.
So for this particular example the matching order is the following:

1. `incl_mods`
2. `program_decl`
3. `decls`
4. `body`
5. `KW_DOT`

These rules can be `tokens` or other grammar rules that have their own constraints, which as said previously have to be
satisfied as well -- think of it as a pre-order traversal. Rules also have their own syntax which is the following:

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

Additionally, grammar rules can have return values and (indirectly) take arguments. In order for a rule to return a value of
type `tag` it has to be declared in the stack type `union` and use the `type` directive to inform `bison` that
we expect that particular rule to return a value of type `tag`. With that in mind, let's go and show how to create a simple
rule.

## Simple rules

A simple rule, is just that... so a simple rule would be one that describes all of the scalar values in `ptuc`, so let's
go ahead and implement it. By our language specification ([here][1]) we see that the *scalar* values are comprised out of
the following:

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
rule or `token` in that case. Let's look at another example.

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

We talked above on how to construct really basic rules, now we will see how to create complex rules --
which (normally) will comprise most of your real world grammars. I normally separate the rules into
two main categories, these being:

1. composition rules
2. lists (or recursive rules)

# Precedence rules

Precedence is a really important aspect of your grammar; that is... if you want to do something
meaningful with it you are bound to be affected by it. But how is precedence demonstrated? Let's first show an example,
support that we have to add three numbers `a`, `b` and `c` (`a` + `b` + `c`). Now also suppose that we have the
following grammar rule for addition:

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
precedence *does* affect the result; one such example is if we had the following:

```c
a * b + c
```

Here we don't have precedence for sequential operations using the same operator but different ones; again if no
precedence is set for the multiplication (`*`) and addition operator (`+`), `bison` would not be certain which
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

Again, sharp readers will see notice in the above code something that I have yet to explain; and again...
they'd be right! I left that for last. Notice that there is no `token` defined for `IF_THEN` or `TYPE_CASE_PREC`, so
can declare precedence for arbitrary symbols and use the term `%prec` to enforce that precedence into a rule.

 ```c
 add_op:
    num `+` num %prec IF_THEN
    ;
 ```

So using the `add_op` rule as previously we can modify it as follows to *enforce* that particular rule to have the
precedence (and associativity) of `IF_THEN` or any other symbol. We will explain why we need `IF_THEN` and
`TYPE_CASE_PREC` when dealing with `ptuc` grammar.

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
* the current lookahead and the entire stack (except the current right-hand side symbols) in the case the parser is *fail-fast*
* the current lookahead and the entire stack (including the current right-hand side symbols) when the `C++` parser catches an exception in `parse`
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

# Creating `ptuc` grammar

In this section I will briefly describe `ptuc` grammar rules and how are structured while also touching in
greater details some implementation related topics that I find are quite interesting.

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
(**not** *reduce/reduce** conflicts). If the number of errors differ, then a compilation error is
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

[1]: ptuc_spec.md
[2]: http://www.gnu.org/software/bison/manual/html_node/_0025define-Summary.html