

# Starting stub of `ptucc`

This is the non-patch starting stub of `ptucc`, refer to the main branch to see the read me for the release version.


# Requirements

I assume that you will run this in a modern (unix-like) platform
-- this includes `Linux` and `Mac OS`, sorry `Windows` users. Here is also
a more detailed dependency list:

* recent `Linux` or `Mac OS`
* `gcc` >= 4.7
* `GNU flex` >= 2.6.0
* `GNU bison` >= 3.0.4
* `GNU Make` >= 4.1
* `valgrind` >= 3.11 (optional(?))
* `git` >= 2.7.4 (optional(?))

Finally if you want to follow the tutorial on how this was made
you are going to need a good text editor like `vim`,
`gedit` or `Sublime` I have no real preference there just use
what you are most comfortable with. Should you want to use an `IDE`
I think you will find it really hard to set it up let alone have
proper syntax highlighting. I personally use `vim` but I have
tested `gedit` as well so both these editors will work fine
as they have proper syntax highlighting already implemented.
`Sublime` does not currently have good support for `flex` (`.l`)
and `bison` (`.y`) files; it's also a paid solution.


# Compiling `ptucc`

After you ensure you are on a supported platform, have
installed the required dependencies and successfully closed this
repo is to open a terminal inside the folder you just created
and type:

```
$ make all
```

The default mode compiles the project in `Debug` mode without using optimizations; this can be changed
if `DEBUG` flag is set to `0` at compile time.


# Compiling a `.ptuc` file

The next step is to compile a `.ptuc` file; if you want to create your own files you will probably
have to read the `ptuc` language definition which is located [here][5]. Alternatively, if you want to just
execute the test or the example files you have two options, which are:

## Make the test

This is a fancy wrapper to just compile and run the `sample001.ptuc` file, hence all you have to do
is to type in your console:

```
$ make test
```

## Compile the file manually

Should you want to compile the `.ptuc` file manually you can do so by following the instructions
below.

First you will have to compile the `.ptuc` file to its `C` representation:
```
$ ./ptucc < infile.ptuc > outfile.c
```
Then compile the `.c` file itself:
```
$ make outfile
```
Then execute it (if you wish):
```
$ ./outfile
```







