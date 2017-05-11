# Pascal-TUC language specification

This is the `official`<sup>(duh)</sup> specification for the language that is recognized, tokenized,
and parsed by `ptucc`; it stems, as its name suggests, from `Pascal` and `TUC`. As you might imagine
by `Pascal` we mean the programming language but I'll leave the origins of `TUC` inside  a mystery
of strawberry flavored cloud for the informed reader to smell and poke in order to find its
mysterious, yet woeful origins.

This guide will outline and define the specification of the said language in the best way possible;
if you think you found any discrepancies do let me know...but since this is a playground<sup>&trade;</sup> language
 chances are slim for someone bothering doing that.

# Program definition

Each *valid* `ptuc` program will be comprised out of a number of `lexical` units that are laid out
based on the `syntax` rules defined in this specification. Both `lexical` units and `syntax` rules
will be thoroughly described in the following sections.

# Lexical units

The *valid* `ptuc` `lexical` can be categorised in the following distinct classes:

 * keywords
 * identifiers
 * integer positive constants
 * real positive constants
 * boolean constants
 * constant strings
 * operators
 * macros
 * modules
 * white-spaces
 * comments

 Each of the above will be explained in its own section below; additionally it has to be noted that
 `ptuc` is a **case-sensitive** language thus for example `FOR` is not the same as `for`.

## Keywords

 The **keywords** are **reserved** words that cannot be used for any-other purpose besides the one that's
 bestowed to them by the language. The complete keyword list for `ptuc` is as follows:

|         |        |         |  Keywords  |        |        |           |
|:-------:|:------:|:-------:|:----------:|:------:|:------:|:---------:|
|   `and`   |  `array` | `boolean` |    `char`    |  `begin` |  `div`   |     `do`    |
|   `else`  |  `for`   |   `end`   |  `function`  |  `goto`  |  `if`    |  `integer`  |
|   `var`   |  `mod`   |   `not`   |     `of`     |   `or`   | `while`  | `procedure` |
| `program` |  `real`  | `repeat`  |     `to`     | `result` | `return` |   `then`    |
|  `until`  | `downto` |    `use`     |   `module`         |        |        |           |


## Identifiers

 The **identifiers** are used for variable, function and procedure names and must start by a
 `_`, `_`, lower or upper case character and can be followed by one or more alphanumeric
 as well as `-`, `_` characters. Additionally identifiers **cannot** have the a value that is equal
 to one of the `ptuc`'s keywords. So based on the previous rules valid identifier values would
 be: `variable`, `x`, `x_19`, `_19y`, `_y` and incorrect values would be: `for`, `1x`, `if`
 and so on.

## Integer positive constants

 Each **integer positive constant** is comprised out of one or more decimal digits without having
 any surplus starting zeros (`0`). In turn valid examples are: `0`, `43`, `12311`, `3`, `11000011`;
 invalid examples are: `0001`, `001`.

 ## Real positive constants

 Each **real positive constant** is comprised out of mandatory *integer* and *fraction* parts while
 optionally having an *exponent* part. The *integer* part is comprised out of at least one or more
 decimal digits without surplus starting zeros (`0`). The *fraction* part is comprised out one
 dot (`.`) followed by at least one or more decimal digits. Finally the *exponent* is comprised
 out of the *case-insensitive* exponent sign (`E`, `e`), an optional sign `+`, `-` as well as
 at least one or more decimal digits without any surplus starting zeros (`0`). Valid examples
 are: `432.0`, `100.000`, `4.2e1`, `0.42e+2`, `0.50E-2`, `5144.012e-3`; invalid examples are
 `00432.0`, `100.0e-0001`.

## Boolean constants

The **boolean constants** depict the values of the boolean `true` (logical true) and
`false` (logical false).

## Constant strings

The **constant strings** are comprised out of a sequence of *normal* or *escape* characters. Normal
characters are defined as all the special and alphanumeric characters not including backslash (`\\`)
the single (`'`) and double (`"`) quote characters. Escape characters start with a backslash (`\\`)
and the ones supported are outlines in the following table.

|  Escape Character  |      Description     |
|:------------------:|:--------------------:|
|       \n           |   newline character  |
|       \t           |     tab character    |
|       \r           | return to line start |
|       \\\          |  backslash character |
|       \\'          |   `'` single quote   |
|       \\"          |   `"` double quote   |

Constant strings are allowed to be multi-line without including any additional newline characters
than the ones present already. Valid constant strings would be: `"a"`, `"\t"`, `'\''`, `"abc"`,
`"Hello world!\n" "Item:\t\"Laser Printer\"\nPrice:\t$142\n"`; invalid ones would include `""car"`,
`'pizza''`

## Operators

The allowed **operators** of `ptuc` are shown in the following table.

|      Category        |               Contains               |
|:--------------------:|:------------------------------------:|
| arithmetic operators |   `+`, `-`, `*`, `/`, `div`, `mod`   |
| relational operators |   `=`, `<>`, `<`, `<=`, `>`, `>=`    |
|    logic operators   | `and`, `or`, `not`, `&&`, <code>&#124;&#124;</code>, `!`  |
|    sign operators    |               `+`, `-`               |
|  assignment operator |                `:=`                  |
|   casting operator   |           `(<data-type>)`            |


The precise function of each operator is shown in the following table.

|      Operator      |      Description     |
|:------------------:|:--------------------:|
|       `+`          |        addition      |
|       `-`          |       subtraction    |
|       `*`          |      multiplication  |
|    `/`, `div`      |     division result  |
|       `mod`        |      modulo result   |
|       `=`          |       equal with     |
|       `>`          |       less than      |
|       `<`          |      greater than    |
|       `<>`         |     not equal with   |
|       `>=`         | greater or equal with|
|       `<=`         |   less or equal with |
|    `and`, `&&`     |     logical `and`    |
|     `or`,  <code>&#124;&#124;</code>    | logical `or`  |
|     `not`, `!`     |    logical `not` |
|   `(<data-type>)`  |    cast to `(<data-type>)`  |

## Delimiters

The allowed **delimiters** of `ptuc` are the following: `begin`, `end`, `;`, `(`, `)`, `,`,
`[`, `]`, `:=`, `:`, `.`.

## Macros

Thankfully in `ptuc` we have baked some elementary `macro` sweetness; that means that we can
macros albeit very basic ones. In `ptuc` macros are processed as *lexical* units that means
when a valid macro name is encountered as an identifier during our lexical analysis it is
replaced by the value of that macro. Macros can be defined anywhere in the file, but they
need to be defined in their own line; thus we have the constraint of "one macro per line".
Macros in `ptuc` have the following syntax:

```pascal
@defmacro <identifier> <string>
```

Additionally in `ptuc`, we can have macro *redefinition*; that means when we have two different
definitions of a said macro its value is equal to the one of the most recent
definition at the time of each replacement. So based on the above this is perfectly legal:

```pascal
@defmacro N 10
(* do stuff *)
n_value := N; (* N here would be replaced by 10 *)
(* do more stuff *)
@defmacro N 100
n_value := N; (* N here would replaced by 100 *)
```

## Modules

Again `ptuc` has baked some (very) elementary `module` support; each `module` is included using `use` keyword
followed by a valid `identifier` which serves as its name. Additionally the file that contains that module
must be of the same filename as that particular module with the extension `.ptuc`. That means that if we
have a module called `nice` it is expected to be contained inside `nice.ptuc`. Modules can be included
at the top of the file **before** the `program` keyword and each one is separated by a  semicolon `;`.

Inside each `module` we have a keyword `module` followed by an `identifier` which has the same value
 as the one used when including it. The body of the `module` is contained between `begin` and `end`
 keywords. At the end a dot `.` is expected to indicate the end of the file.

 Modules can contain **declarations** but not orphan statements; that means inside a `module` we can
 have one or more `type`, `function`, `procedure` and `variable` declarations. A difference between a
 `program` and a `module` is that **all** declarations end with a semicolon `;`, even the last one --
 which is not the case in the main `program`.

A valid module would be the following:

 ```pascal
module nice
begin
    type
        intfunc = function(n: integer) : integer;
        string = array of char;
    var f: integer;

    procedure eval(prompt: string; f: intfunc; val: integer);
    begin
	    writeString(prompt);
	    writeString('('); writeInteger(val); writeString(')=');
	    writeInteger(f(val));
	    writeString("\n")
    end;
end.
 ```

This `module` could be included as

```pascal
use nice;
```

## Skipped elements

Besides the previously mentioned lexical units a `ptuc` program might also contain some elements
that meant to be ignored. That basically means that while they are valid, parsed and tokenized
correctly we just discard the output. These elements in `ptuc` are the following:

* while-spaces
* single/multi-line comments

### White-spaces

These are basically sequences that are comprised out of at least one or more space (` `),
tab (`\t`), line feed (`\n`) or carriage return (`\r`) characters.

### Comments

In `ptuc` we support two (2) types of comments; these are

* single-line comments
* multi-line comments

Their only essential difference as their name suggests is that the former is able to comment a
*single* line whereas the latter can comment an arbitrary large number of lines. Single-line
comments start with `//` and discard the contents of that line up to the first line feed
(`\n`) character encountered. Multi-line comments start with `(*` and consume everything
(including special characters) until their matching reverse pair: `*)` is read. Nested
multi-line comments are **not** supported.

# Syntax rules

Now we will describe the syntax rules which comprise the correct ordering of the `lexical` units
that are generated by the `lexer`. This section is segmented in the following sections

 * Program
 * Data-Types
 * Variables
 * Sub-programs
 * Default sub-programs
 * Expressions
 * Statements

## Program

Each *valid* `ptuc` **program** can be inside a file with an extension `.ptuc` and is comprised out of
the its `main` *procedure* which can contain one or more sub-programs (functions, procedures). The
`main` procedure has the following layout:

 * program header
 * declarations (optional)
 * main body

These are separated by a semicolon `;`. One semicolon is required for each separate declaration,
so if we have both variables and sub-program declarations we would have an equal number of semicolons
each one separating these structural units.

### Program header

Each `ptuc` program has a header which has the following syntax:

```pascal
program <identifier>;
```

Where `<identifier>` is a valid identifier as defined previously and indicates the program name; its followed
 by a semicolon. A valid program header would be the following:

```pascal
program foo;
```

### Declarations

Declarations mat be empty of include one or more different declarations of *variables*,
*named-types* or *sub-programs* in any order, although it has to be noted that you cannot
use something that has not been declared previously than the place of usage.

### Main body

The `main` body is comprised out of a *complex* statement and ends with a dot (`.`). This is the only case
that a complex statement is allowed to end with a dot (`.`).

### Simple Example

A complete and simple example of a *valid* `ptuc` program is the following:

```pascal
program foo;
var
    x: integer;
begin
    x := 1+2;
    writeInteger(x);
end.
```

## Data-Types

In `ptuc` we have baked in support for four (4) basic data-types, which are the following:

| Data-type name |   Description   |
|:--------------:|:---------------:|
|    `integer`   | integer numbers |
|    `boolean`   |   logic values  |
|     `char`     |    characters   |
|     `real`     |   real numbers  |

Additionally `ptuc` has support for the following non-scalar types (e.g. arrays)

 * `array [n] of T`: one-dimensional arrays that are comprised out of `n` elements of type `T`; `n` must
 be a positive constant integer and `T` a valid basic or named-type. A valid example would be:
 `array [5] of integer`.
 * `array [n]...[k] of T`: multi-dimensional arrays that are comprised out of elements of type `T`;
 `n...k` must be positive constant integers and `T` a valid basic or named-type. A valid example would be:
  `array [5][10] of char`.
 * `array of T`: arrays that are of unknown number of elements of type `T`; `T` must be a valid
 basic or named-type.
 A valid example would be: `array of real`.
 * `function (paramList) : Treturn`: function prototype with a defined signature; that means that we
 know beforehand the types of both its arguments as well as its return type. All types must be valid
 basic or named-types. A valid example would be: `function(x, y: integer; z: char): char`.

It has to be noted that when using tables the subscript index value must be again a positive integer
constant, so assuming `f` is an array of a valid type `T` then we can do `f[1]` but not `f[-1]`.

### Named-types

As we previously mentioned besides basic data-types, we have baked in support for custom data-types
which can be used as an abbreviation; much like `C`'s `typedef`. These types can be declared as follows:

```pascal
type
    <identifier> = T
```

Which basically lets us use `<identifier>` in place of `T`; this is really handy as it lets us write fewer
code by providing "shortcuts" such as:

```pascal
type
    str = array of char;
```

So instead of just writing `array of char` we can just use as `str`. This can be taken further into
functions:

```pascal
type
    vec = array [3] of real;
    f = function(vec: vector): vector;
```

## Variables
Variables declaration in `ptuc` start with the keyword `var` and are followed by at least one or more
comma separated identifiers ending with a colon `:` and a valid type. We can have chained
variable declarations of the same or different type inside the same `var` but each one is separated with
a semicolon `;`. A valid example would be:

```pascal
(* first var, showning chained variables *)
var i: integer;
    f, x: real;
    s: array[10] of char;

(*
   more stuff before main begin
*)

(* we can have more than one var *)
var c: real;
    string: array of char;
```
## Sub-programs

In `ptuc` sub-programs have two flavors:

 * procedures
 * functions

Each sub-program is a structural unit and is comprised out of the following:

 * sub-program header
 * declarations: a sub-program like the main program can contain one or more sub-programs which
 are local to that particular sub-program and cannot be accessed outside of it.
 * sub-program body

These are separated again by a semicolon `;`. One semicolon is required for each separate declaration,
so if we have both variables and sub-program declarations we would have an equal number of semicolons
each one separating these structural units.

### Sub-program header

The sub-program header contains the sub-program type (function, procedure), its name,
its arguments (if any) and depending whether it is a procedure or function its return type.
It has to be noted that the program name *must* be followed by a left (`(`) and right (`)`) parenthesis
pair inside which the arguments are placed (if any).

 So for example these headers are valid:

```pascal
function foo() : integer
procedure proc()
```

While these are not
```pascal
function foo : integer
procedure proc
```

### Declarations

Declarations mat be empty of include one or more different declarations of *variables*,
*named-types* or *sub-programs* in any order, although it has to be noted that you cannot
use something that has not been declared previously than the place of usage. Contrary to the
`main` procedure declarations the ones made inside a sub-programs can only be used by itself
and their defined sub-programs (if any).

### Sub-program body

The sub-program body is comprised out of a *complex* statement and ends with a semicolon (`;`).

## Default sub-programs

We baked into `ptuc` the support of some predefined support, hence these functions are global
and one can access them anywhere in the program. These function headers are the following:

Reading basic types (from `stdin`):
 * `readInteger(): integer`
 * `readReal(): real`
 * `readString(): array of char`

Writing basic types (to `stdout`):
 * `writeInteger(n: integer)`
 * `writeReal(n: real)`
 * `writeString(s: array of char)`

## Expressions

In a programming language expressions are arguably the most important part. Basic expression types
are constants, variables of any type and function/procedure calls. More complex expressions can be
created by using operators and or parentheses.

In particular the `ptuc` operators are split into two categories, the ones that take one (1) argument
(e.g. `not`) and the ones that take two (2) arguments (such as `=`). The operators that have one
argument are placed in front of their argument (using prefix notation) but are defined afterwards
(using postfix notation). Operators that take two (2) arguments are *always* types in between their
arguments (using infix notation). Decomposition and parsing happens in a left-to-right fashion.

To avoid syntax ambiguities the table below defines the *precedence* of each operator as well as
their arguments and the notation used. The operators are categorized in groups based on their
relative precedence. The higher a group is in the table the higher its precedence, hence Logical
`not` has the highest precedence and Logical`or` the lowest. The full precedence table follows.

|             Operators           |               Description                |   No. of arguments   |   Associativity   |
|:-------------------------------:|:----------------------------------------:|:--------------------:|:-----------------:|
|             `not`, `!`          |        Logical `not` operators           |   1   |  prefix, right   |
|              `+`, `-`           |         Numeric sign operators           |   1   |  prefix, right   |
|          `(<data-type>)`        |            Casting operator              |   1   |  prefix, right   |
|     `*`, `/`, `div`, `mod`      |  Arithmetic operators (minus ones below) |   2   |   infix, left    |
|              `+`, `-`           |      Addition/Subtraction operators      |   2   |   infix, left    |
| `=`, `<>`, `<`, `>`, `<=`, `>=` |          Relational operators            |   2   |   infix, left    |
|             `and`, `&&`         |         Logical `and` operators          |   2   |   infix, left    |
| `or`, <code>&#124;&#124;</code> |          Logical `or` operators          |   2   |   infix, left    |


Some valid examples of expression are the following:

```pascal
-a                      (* negative of a *)
a + b * (b / a)         (* arithmetic expression *)
4 + 50.0*x / 2.456      (* arithmetic expression *)
(a+1) mod cube(b+3)     (* addition operator, function call *)
a + (a <> b)            (* logic and relational expressions *)
a[1] + b[k]*2           (* arithmetic and relational operators *)
15.7e-2 * (real) 45     (* arithmetic expression with casting *)
```

It has to be noted that function calls when used in conjunction with an operator (such as
addition (`+`) or assignment (`:=`)) they should be treated as *expressions* instead of statements.
So for example the following

```pascal
a := f()        (* function call *)
b := cube(b+3)  (* another function call *)
```

Should be perfectly valid.

## Statements

In `ptuc` we support **statement** which again as expressions have two formats, *simple* and *complex*.
All statements are considered simple besides the one statement that is explicitly named as *complex*.

### Complex statement

Each complex statement is comprised one or more *simple* statements; each statement is separated with
the next by a semicolon (`;`). These statement are encapsulated in `begin` and `end` keywords. A valid
example would be:

```pascal
(* start a complex statement *)
begin
    (* have more simple statements *)
    x := 1;
    y := 2
end
```

Notice that the *last* statement in each *complex* command *does not* have a semicolon (`;`); this is
by design and intentional.

### Simple statements

Simple statements are all other statements that our language can have.

#### Assign statement

The assign statement is responsible for assigning to a variable `v` and expression `expr` and has
the following syntax:

```pascal
v := expr
```


#### Special function assign statement (`result`)

Inside functions we can have a special assignment, which assigns an expression to the special
`result` variable. It has the following syntax: `result := expr`, where `expr` is a
valid expression.

#### if-then-else statement

The known `if-then-else` statement has the following syntax: `if e then s_1 else s_2` where
`e` is an expression and `s_{1,2}` are simple of complex statements.

#### for statement

The `for` loop statement has the following syntax: `for v := e_1 to e_2 do s`
(increments `e_1` up to `e_2`) or `for v:= e_1 downto e_2 do s`
(decrements `e_1` up to `e_2`) where `v` is a variable, `e_{1,2}`
are expressions and `s` a simple or complex statement.

#### while statement

The `while` loop statement has the following syntax in: `while e do s` where `e` is an expression
and `s` a simple or complex statement.

#### repeat until statement

The `repeat-until` loop statement has the following syntax: `repeat s until e` where `s` is a simple
or complex statement and `e` a valid expression.

#### label statement

The `label` statement defines a block of code that would be executed if we used a `goto` statement
to jump to it. The `label` statement has the following syntax: `l: s` where `s` is a simple or
complex statement.

#### goto statement

The `goto` statement is used to do unconditional jumps to labels placed within our code, hence
`goto` has the following syntax: `goto l` where `l` a valid label inside the same structural unit
`goto` was called.

#### return statement

The `return` statement is responsible when executed to terminate the function/procedure it is
called from. Depending on whether it is called from `main`, `procedure` or a `function` different
things happen. Let examine each case separately

* `main`: if we call `return` inside our `main` procedure then our program terminates. No return value
 is expected and thus has no arguments.
* `procedure`: if we call `return` inside a procedure we have the immediate return of the procedure that
the statement was executed within. No return value is expected and has no argument.

* `function`: if we call `return` inside a function we have the immediate return of the function
that the statement was executed within. In the case of functions we *expect* to have a return
value of type `T`; thus we can have a simple `return`, which returns the current value of
`result` otherwise we can also return an expression, thus `result expr` would be perfectly
valid within a function as long as it returns the same type `T`.

#### function/procedure call statement

Function/Procedure call statement is comprised out of the *single* call of the function/procedure
`f` while also followed by its arguments (if any) that are treated as expressions; thus it has the
following reference format:

```
f(expr_1, expr_2, ..., expr_n)
```
Where `f` the function name and `expr_{1...n}` its arguments as expressions.

In case we call the function in a statement alone when the function/procedure itself is treated as
a statement, thus the following should be perfectly valid.

```pascal
function_call(a, b); (* statement, while a,b are expressions *)
proc_call(d, c);     (* another statement, while d, c are expressions *)
```

# Mapping `ptuc` to `c` rules

This section will outline the mapping of the `ptuc` syntax to its `C` equivalent. Unfortunately `ptuc`
cannot be compiled using `c89` but only `c99` (1999) and `c11` (2011); explaining these is certainly
out this specification context so you should read up the `C` standards in question for more details.
It has to be noted that when mentioning `C` from now on I am referencing to a version of `C` >= `c99`.

## Mapping constants and types

The types of `ptuc` can be easily mapped into their respective `C` equivalents; details on how to
map the basic types supported in `ptuc` are shown in the table below.

| `ptuc` type    |  mapped `C` type   |
|:---:|:---:|
|  `integer`   |  `int`   |
|  `boolean`   |  `bool`  |
|  `char`      |  `char`  |
|  `real`      |  `double` |
| `array [n_1]...[n_k] of T` | `T[n_1]...[n_k]` |
| `array of T` | `T*` |
| `function (a_1: T_1; ... a_k: T_k) : Treturn` | `Treturn (*)(T_1 a_1, ..., T_k a_k)` |

Notes: `T` above refers to the `data-type` of that lexical unit; similarly `Treturn` refers to the
`data-type` that is returned by that construct (i.e. a function).

Actual `ptuc` constants, say for example positive constant integers (and the others) can be mapped
using the above table as a reference quite trivially.

## Mapping of structural units

A structural unit can contain optionally variable, function and procedure declarations alongside
with the mandatory main function body. The main structural unit is mapped to a respective
`.c` file which contains all the said declarations as well as the `main` function
that contains the aforementioned logic.

### Mapping named-types

In `ptuc` a named type of the following structure:

```pascal
type
    foo = T;
```

can be mapped in `C` using:

```c
typedef T foo
```

Special care should be taken when handling array-based named types, for example

```pascal
type
    foo = array[n] of T
```

This should be mapped in `C` as follows:

```c
typedef T foo[n]
```

### Mapping variables to types

Additionally, a variable of `type` in `ptuc` can be mapped in `C` as shown below.

The following `ptuc` variable declaration segment:

```pascal
var
    myfoo, mybar: T;
```

Would be mapped in `C` as follows:

```c
T myfoo, mybar;
```

### Mapping routines

As we know `ptuc` has two (2) types of subprograms, namely `functions` and `procedures`. Their only
significant differences as shown above is that a `function` can have a return value of type `T`
and a special variable called `result` that can store the return result. On the other hand
procedures have no return type nor the `result` variable.

This makes mapping to `C` easy, as `C` does not discriminate its function types so `ptuc`
procedures are mapped to `void` `C` functions as is shown below.

The following `ptuc` procedure:
```pascal
procedure
foo(x_1: T_1; ...; x_n: T_n)
```

Would be mapped in `C` as follows:

```c
void
foo(T_1 x_1, ..., T_n x_n)
```

On the other hand `ptuc` functions are mapped with `C` functions that return
their `T` type as is shown again below.

The following `ptuc` function:
```pascal
function
foo(x_1, x_2: T_1; ...; x_n: T_n): Treturn
```

Would be mapped in `C` as follows:
```c
Treturn
foo(T_1 x_1, T_1 x_2, ..., T_n x_n)
```

### Mapping program statements

These are basically the same as in `C` with a few exceptions and that's why there are differences
in the operators that perform a particular operation; a good example is the *assignment* operator
as in `C` is `=` and in `ptuc` is `:=`. I am sure that you can easily discern how to map basic
`ptuc` operations to their `C` equivalent...

## Mapping built-in functions

As we previously noted `ptuc` has some predefined "standard" functions that can be easily
implemented using `C` wrappers; in this specification I'll give you the suggested function
that you have to wrap around the function in order to perform the desired action in `ptuc`
but not the actual implementation.

| `ptuc` call | `C` wrapper|
|:-------------------------------:|:------------------------:|
|  `readString(): array of char`  |           `fgets`        |
|     `readInteger(): integer`    | `strtol` casted to `int` |
|        `readReal(): real`       |  `strtod` without cast   |
| `writeString(s: array of char)` |          `printf`        |
|   `writeInteger(n: integer)`    |          `printf`        |
|       `writeReal(n: real)`      |          `printf`        |

Please note that, while for example I indicate the `printf` as a suitable wrapper for all write
functions you will have to provide the *correct* printing format in `printf` in order to
successfully print in the desired format.
