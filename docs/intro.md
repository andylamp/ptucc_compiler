# How to create a language Parser.

This guide is meant as an introduction on how to use `flex` and `bison` in order to create your own
language parser. For the purposes of this guide we will base our language into a *reduced* and *slightly
flavored* version of `Pascal`, called `Pascal-TUC`, the full specification of `ptuc` can be found
[here][1]. I suggest you have at least a quick glance to its specification as it will make many things 'click'
quite a bit easier.

# Parts

Since the lexer and parser are quite the beasts on their own naturally you'd guess that they
have their separate chapters; and you'd be right. Additionally, I have also created a starting chapter
in order to familiarize the daring reader with the starting stub and tools that are needed in order
to follow through this tutorial. Hence we have the following chapters:

* Introduction (this)
* Starting code and tools ([here][2])
* `ptuc` Lexer ([here][3])
* `ptuc` Parser ([here][4])

# Goals

In this tutorial we will create two things, which are the following.

 * `ptuc` language lexer
 * `ptuc` language parser

But the parser comes with a *twist*; we can map `ptuc` into `C` as long as its a version `>= c99`; that
means we can create a `.c` file which is mapped from its respective `ptuc` file that can be compiled
and executed using a `C` compiler. This is pretty neat as our project output isn't only the usual
token console spam (as is the case with most "playground" compiler projects).


# Requirements

These are the same listed in the initial `README` but... for completeness sake here they are again; you
can skip this if you've already read this.

For this project I assume that you will develop it using a modern (unix-like) platform --
this includes `Linux` and `Mac OS`, sorry `Windows` users. Here is also a more detailed
dependency list:

* recent `Linux` or `Mac OS`
* `gcc` >= 4.7
* `GNU flex` >= 2.6.0
* `GNU bison` >= 3.0.4
* `GNU Make` >= 4.1
* `valgrind` >= 3.11 (optional(?))
* `git` >= 2.7.4 (optional(?))


Finally you are going to need a good text editor like `vim`,
`gedit` or `Sublime` I have no real preference there just use
what you are most comfortable with. Should you want to use an `IDE`
I think you will find it really hard to set it up let alone have
proper syntax highlighting. I personally use `vim` but I have
tested `gedit` as well so both these editors will work fine
as they have proper syntax highlighting already implemented.
`Sublime` does not currently have good support for `flex` (`.l`)
and `bison` (`.y`) files; it's also a paid solution.

# What this guide is and isn't

This guide is a *demonstration* of common techniques and practices on how to create your own language *lexers*,
*parsers* and combining them. I use extensive insight gained from the manuals of the tools used (as one should)
and I suggest you refer to them often in case of doubt.

[1]: ptuc_spec.md
[2]: ptuc_start.md
[3]: ptuc_lexer.md
[4]: ptuc_parser.md