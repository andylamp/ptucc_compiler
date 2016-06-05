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
separate segments as opposed to `struct` fields. We can have as many different tags as we want inside the union.

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
%type <tagB> TYPE_NAME_B TYPE_NAME_C TYPE_NAME_F
```

The `tags` are again defined inside the union as are the tokens -- basically the same rules apply here as well.

# Precedence rules

# Destructors

# Constructing grammar rules

## Simple rules

## Complex rules

# Epilogue

