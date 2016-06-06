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

1) `incl_mods`
2) `program_decl`
3) `decls`
4) `body`
5) `KW_DOT`

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
we expect that particular rule to return a value of type `tag`. With that in mind, let's go an show how to create a simple
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

1) composition rules
2) lists (or recursive rules)

# Precedence rules

Precedence is a really important aspect of your grammar; that is... if you want to do something 
meaningful you are bound to be affected by it. But let's say


# Destructors

# Creating `ptuc` grammar

In this section I will briefly describe `ptuc` grammar rules are structured while also touching in
greater details some implementation related topics that I find are quite interesting.

# Special bison commands

Here is a simple summary of the `bison` special commands and a brief description on 
what they do -- a *cheat-sheet* if you'd like to call it that.

* `%union`
* `%token`
* `%type`
* `%right`
* `%left`
* `%nonassoc`
* `%start`
* `%expect`
* `%pure_parser`
* `%raw`
* `%no_lines`
* `%token_table`
* `%define`


# Epilogue

[1]: ptuc_spec.md