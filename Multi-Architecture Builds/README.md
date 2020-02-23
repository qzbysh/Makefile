> 本文由 [简悦 SimpRead](http://ksria.com/simpread/) 转码， 原文地址 http://make.mad-scientist.net/papers/multi-architecture-builds/#vpath

> A very common requirement for build systems today is allowing compilation of the same code in multiple environments, at the same time. That is, given one set of source code, developers want the ability to create more than one set of targets from it.
> 
> This can be for anything from a debugging vs. an optimized version of the code, to building it on two or more different operating systems and/or hardware platforms.
> 
> As important as this is, it’s not entirely obvious how to get it working well using `make`. The first attempts, usually involving VPATH, are generally unsuccessful (see [How **Not** to Use VPATH](http://make.mad-scientist.net/papers/how-not-to-use-vpath/ "How Not to Use VPATH") for more details).
> 
> However, it _is_ possible to create a readable, useful, and usable build environment for multi-architecture builds. Here I describe a method for doing this.

1.  [Other Common Methods](#other)
    1.  [Source Copy Method](#sourcecopy)
    2.  [Explicit Path Method](#explicitpath)
    3.  [VPATH Method](#vpath)
2.  [The Advanced VPATH Method](#advanced)
    1.  [Single Target Directory](#single)
        1.  [Standard Makefile Template](#template)
        2.  [The `target.mk` File](#target.mk)
    2.  [Multiple Target Directories](#multiple)
        1.  [Testing for Extra Target Directories](#testingextra)
        2.  [Standard Makefile Template with Multiple Targets](#multitemplate)
        3.  [The `target.mk` File with Multiple Targets](#multitarget.mk)
    3.  [Sample Implementation](#sample)
3.  [Acknowledgments](#acknowledgments)
4.  [Revision History](#history)

First we’ll think about some other methods used for multi-architecture builds, and discuss the pros and cons. Ideally we’d like a method that combined all the important advantages while avoiding all the disadvantages.

There are three main approaches to this problem that are most common: the [**Source Copy**](#sourcecopy) method, the [**Explicit Path**](#explicitpath) method, and the [**VPATH**](#vpath) method.

Source Copy Method
------------------

This approach is fairly straightforward. At its simplest, it’s merely a physical copy of the entire source tree for each separate build type you want to create. Every time you want to build, you copy the sources to a new directory and build it there with whatever options you require. If you want to build it differently, copy the source to another directory and repeat.

The good point about this method is that makefiles are very simple to write, read, and use. The makefile creates the targets in the same directory as the sources, which is very easy. There is no need to resort to VPATH or alternate directories at all. Also, you can run builds such as “`make foo.o`” and it works correctly.

Unfortunately the downsides are more significant. Suppose you change a file; you must have some way of propagating those changes to all the copies of the tree, for testing: managing this so you don’t forget one and wreck your build or, even worse, introduce odd bugs is quite a challenge. And of course, multiple versions of the entire source tree uses quite a bit more disk space. Note to mention the “thumb-twiddling” time involved while waiting for the tree to copy in the first place.

#### Symbolic Link Farms

There is a flavor of the Source Copy method often used on UNIX called the symbolic link farm. The X Consortium, for example, uses this flavor. Here, a program or shell script is used to first create a “shadow” directory hierarchy: a copy of the directory structure is created, but no actual files are copied over. Next, instead of copying the source files themselves, the program or script creates a symbolic link for each file from the “shadow” hierarchy back to the “true” hierarchy.

The symbolic link farm has the same advantages as the Source Copy, and it ameliorates the worst of its disadvantages: since all but one of the files are sym links you don’t have to copy your changes around (but you do have to be careful to edit the original, or set up your editor to handle this situation properly–and some can’t). Link farm copies take up considerably less space and are faster to create (though still not free) than normal copies.

Nevertheless, symlinks can be annoying to work with; a small example: you need to remember to use the `-L` option to `ls -l` when you want to see the size or modification time of the actual file. Also, adding new directories or files to the source tree can be problematic: you need to remember to add them to the master copy, and have a way of updating the links in all your farms.

Explicit Path Method
--------------------

Better (IMO) than the previous one is the Explicit Path method. You might take a look at the final result in [How **Not** to Use VPATH](http://make.mad-scientist.net/papers/how-not-to-use-vpath/ "How Not to Use VPATH") for an example. In this method, you write your makefiles such that every reference to every target is prefixed with the pathname where it exists. For multiple architectures, you merely change that pathname (it’s obviously always stored in a variable!) The pathname can (and probably should) be calculated internally to your makefiles based on the current host architecture, or compiler flags, or both.

Often the target directory is a simple subdirectory of the current directory, but it could also be someplace completely different; this can allow, for example, building sources that exist on read-only media without copying them elsewhere first: the sources are left where they sit, and the targets are put elsewhere, in a writable area. If you write your makefiles carefully you can easily accommodate both styles by simply changing a variable value or two.

Obviously since you’re not copying sources anywhere, you avoid all that hassle of remembering what to update, when.

The problem here is with the makefiles. First, they’re more difficult to read, write, and modify: every reference to every target must be prefixed by some variable. This can make for a lot of redundancy in your makefiles. Following [Paul’s Fourth Rule of Makefiles](http://make.mad-scientist.net/papers/rules-of-makefiles/#rule4 "Rule #4") can alleviate this, but it’s still there.

Second, you cannot use simple rebuild commands like “`make foo.o`“; you must remember to prefix it with the target directory, like “`make '$(OBJDIR)/foo.o'`“. This can get unwieldy quickly.

The VPATH Method
----------------

Eh? VPATH? But didn’t [we discover](http://make.mad-scientist.net/papers/how-not-to-use-vpath/ "How Not to Use VPATH") that VPATH wasn’t useful for multi-architecture builds? Well, not quite. [We decided](http://make.mad-scientist.net/papers/rules-of-makefiles/#rule3 "Rule #3") VPATH wasn’t useful for locating _targets_; however, it’s extraordinarily handy for locating _source_ files.

So, this method does just that. Like the [source copy method](#sourcecopy), we write our makefiles to create all targets in the current working directory. Then, the makefile uses VPATH to locate the source files for use, so we can write the source filenames normally and without a path prefix either.

Now all that has to be done is invoke the build from within the _target_ directory and voila! It works. The makefiles are tidy and easy to understand, without pathnames prefixed everywhere. You can run builds using the simple “`make foo.o`” syntax. And you’re not required to expend time or disk space creating multiple copies of the source tree.

The most popular example of this method are the build environments created with a combination of GNU autoconf and GNU automake. There, the `configure` script is run from a remote directory and it sets things up for you in that remote directory without modifying the original sources. Then you run a VPATH-capable `make`, such as GNU `make`, and it uses VPATH to locate the source files in the distribution directory, while writing the target files in the directory where you invoked the build: the remote directory.

#### But wait a minute…

Unfortunately, there’s a painful thorn on this rosebush. I glossed over it above, but the phrase “invoke the build from within the _target_ directory” hides a not-insignificant annoyance for most build environments.

First, you have to `cd` to another directory from the one you’re editing in to actually invoke the build. But even worse, the makefile for your build is back in the source directory. So, instead of just typing “`make`“, you need to run “`make -f SRC/Makefile`” or similar. Ugh.

The GNU autoconf/automake tools avoid this latter issue by putting the makefile in the target directory (the `configure` script actually constructs it at configure time from a template contained in the source directory). Or, you could set up a symbolic link in the target directory pointing back to the makefile in the source directory. This can work, but it’s still annoying and doesn’t address the first problem at all.

What would be really great is if we could combine the best parts of _all_ three of the above methods. And why not? Looking at them again, the closest thing to what we really want is the [VPATH method](#vpath). It’s almost perfect. What does it need to make it just what we want? Well, we need to avoid having to change directories. So, what the advanced VPATH method describes is a way of convincing `make` itself to change directories _for_ you, rather than requiring you to do it yourself.

The algorithm is simple: when `make` is invoked it checks the current directory to see if the current directory is the target. If it’s not, then `make` changes to the target directory and re-invokes itself, using the `-f` option to point back to the correct makefile from the source directory. If `make` is in the target directory, then it builds the requested targets.

How can this be done? It’s not difficult, but it requires a few tricky bits. Basically, we enclose almost the entire makefile in an `if-then-else` statement. The test of the `if` statement checks the current directory. The `then` clause jumps to the target directory. The `else` clause contains normal `make` rules, writing targets to the current directory. I use GNU `make`‘s `include` preprocessor feature to keep individual makefiles simpler-looking.

Single Target Directory
-----------------------

We’ll start with the basic case: each source directory is completely built in a single target directory.

### Standard Makefile Template

Here’s a sample makefile:

```
ifeq (,$(filter _%,$(notdir $(CURDIR))))
include target.mk
else
#----- End Boilerplate

VPATH = $(SRCDIR)

Normal makefile rules here

#----- Begin Boilerplate
endif
```

Note the first and last sections are the same in every makefile. The included file hides all the tricky bits from the casual user. All the user needs to do is create her makefile in the _Normal makefile rules here_ section, without worrying about where the targets go or where the source files are. These rules are written as if everything occurs in the current directory.

Let’s go through this line-by-line:

Not too bad. So, what’s in this magical `target.mk` file?

### The `target.mk` Makefile

This file is where all the magical bits are hidden. If make is parsing this file, it means that the user invoked the build in the source directory and we want to convince `make` to throw us over into the target directory. Of course, we want to preserve all the same command line values the user provided, etc.!

Here we go:

```
.SUFFIXES:

ifndef _ARCH
_ARCH := $(shell print_arch)
export _ARCH
endif

OBJDIR := _$(_ARCH)

MAKETARGET = $(MAKE) --no-print-directory -C $@ -f $(CURDIR)/Makefile \
                 SRCDIR=$(CURDIR) $(MAKECMDGOALS)

.PHONY: $(OBJDIR)
$(OBJDIR):
        +@[ -d $@ ] || mkdir -p $@
        +@$(MAKETARGET)

Makefile : ;
%.mk :: ;

% :: $(OBJDIR) ; :

.PHONY: clean
clean:
        rm -rf $(OBJDIR)
```

Let’s see what’s going on here.

```
This is the first magic bit. This forces all (well, almost all) the builtin rules to be removed. This is crucial: we don’t want make to know how to build anything. Below, we’ll tell it how to build everything, and we don’t want it using any other rules.

To be truly comprehensive, it’s best to invoke make with the -r option. However, that usually means you need a wrapper around make that users will run, so they don’t forget. In my opinion a make wrapper script is a great idea and I always use one, but opinions differ.

Even if you do add -r, this line doesn’t hurt.
```

Multiple Target Directories
---------------------------

Sometimes you’ll want a single invocation of the build to create files in multiple target directories. A common example of this is source code generators: in this case you want to build one set of targets (the source code) in a common target directory that can be shared by all architectures, then compile the source code into an architecture-specific directory. This can certainly be done with this architecture, but it’s slightly more complicated.

In the example above we split the makefile into two parts with an if-else statement: one part that was run when we were in the source directory, and one part that was run when we were in the target directory. When we have multiple target directories, we need to split the makefile into more than two parts: an extra part for each extra target directory. Then we’ll jump to each target directory in order and re-invoke make there. In this example we’ll stick with one extra target directory, so we’ll need three parts to the makefile.

### Testing for Extra Target Directories

The first complication that arises with multiple target directories is, how do you decide if you have one or not? If all your directories have multiple targets, you’re fine; you can modify `target.mk` to jump to them in turn for all directories. However, most often only a few directories will need an extra target directory, and others won’t. You don’t want to have extra invocations of make in all your directories when most aren’t useful, so somehow you need to decide which directories have extra targets and which don’t.

The problem is, that information has to be specified in your makefile _before_ you include the `target.mk` file, because that file is what needs to know.

The simplest way is to have the extra target directory exist before the build starts, then just have the `target.mk` test to see if the directory exists. The nice thing about this is it doesn’t require any special setup in the source makefiles, all the complexity can be encapsulated in `target.mk`. This is a good way to go if the extra target directory is the same everywhere (which is often the case)—for example, if it holds constructed source code that’s common between all architectures you might call it `_common`, then test for that:

```
EXTRATARGETS := $(wildcard _common)
```

Above I recommended against pre-creating target directories, but this can be considered a special case: it will always need to exist before any normal target can be built, so having it exist always isn’t as big of an issue.

However, if you don’t want the directory to pre-exist, or you can’t use this method for some other reason, the other option is to modify the source makefile and set an EXTRATARGETS variable. The minor disadvantage here is that it must be done by the user, and it must be set before the `if`-statement is invoked, meaning in the boilerplate prefix section which is no longer quite so boilerplate.

There are about as many possible ways to permute this as there are requirements to do so; here I’m going to provide an example of a simple case.

### Standard Makefile Template with Multiple Targets

Here’s an example of a standard source makefile for a directory that has two targets: the `_common` target and the $(OBJDIR) target. This example assumes the first method of testing for the extra target directory, done in `target.mk`. If you choose another method, you need to insert something before the first line below.

```
ifeq (,$(filter _%,$(notdir $(CURDIR))))
include target.mk
else
ifeq (_common,$(notdir $(CURDIR)))
VPATH = $(SRCDIR)
.DEFAULT: ; @:

Makefile rules for _common files here

else

VPATH = $(SRCDIR):$(SRCDIR)/_common

Makefile rules for $(OBJDIR) files here

endif
endif
```

The new sections are in blue text above. You can see what we’ve done: we’ve added another `if`-statement into the target section of the makefile, splitting it into two parts. We execute the first part if we’re in the `_common` target directory, and the second part if we’re in the $(OBJDIR) target directory.

In the `_common` target directory, we use VPATH to find sources in the source directory. In the $(OBJDIR) target directory, we use VPATH to look in _both_ the source directory _and_ the `_common` directory.

There is one tricky bit here, the `.DEFAULT` rule. This rule, with a no-op command script, essentially tells make to ignore any targets it doesn’t know how to build. This is necessary to allow commands like “`make foo.o`” to succeed. Remember that regardless of the target you ask to be built, make will be invoked in both the common and the target directories. If you don’t have this line then when `make` tries to build `foo.o` in the common directory, it will fail. With this rule, it will succeed while not actually doing anything, trusting the target directory invocation to know what to do. If that invocation fails you’ll get a normal error, since the `.DEFAULT` rule is only present in the section of the makefile that’s handling the common directory builds.

If you have some common rules or variables that need to be set for both the `_common` and the $(OBJDIR) target directories, you can insert them between the first `else` and the second `ifeq`, above; that section will be seen by both target directory builds but not by the source directory build.

Obviously this example is geared towards handling generated source code; your need for multiple targets in the same build may be quite different and not require this type of interaction.

### The `target.mk` File with Multiple Targets

In the last section we saw how the user separates her rules into different sections depending on which target directory is being built. Let’s see how to write a `target.mk` file that allows jumping into multiple target directories. It’s fairly straightforward.

```
.SUFFIXES:

ifndef _ARCH
_ARCH := $(shell print_arch)
export _ARCH
endif

OBJDIR := _$(_ARCH)

MAKETARGET = $(MAKE) --no-print-directory -C $@ -f $(CURDIR)/Makefile \
                 SRCDIR=$(CURDIR) $(MAKECMDGOALS)

EXTRATARGETS := $(wildcard _common)

.PHONY: $(OBJDIR) $(EXTRATARGETS)
$(OBJDIR) $(EXTRATARGETS):
        +@[ -d $@ ] || mkdir -p $@
        +@$(MAKETARGET)

$(OBJDIR) : $(EXTRATARGETS)

Makefile : ;
%.mk :: ;

% :: $(EXTRATARGETS) $(OBJDIR) ; :

.PHONY: clean
clean:
        $(if $(EXTRATARGETS),rm -f $(EXTRATARGETS)/*)
        rm -rf $(OBJDIR)
```

Again, additions to this file from the previous example are in blue text.

The first change sets the variable `EXTRATARGETS` to `_common` if that directory exists, or empty if it doesn’t. If you are using a different method of determining the value of $(EXTRATARGETS) you can change this line (or, leave it out if the source makefile is setting it for you).

Next, we include the value of $(EXTRATARGETS) (if any) as a phony target to be built, and use the same sub-make invocation rule for building it as we use for $(OBJDIR).

Next we declare a dependency relationship between $(OBJDIR) and $(EXTRATARGETS) (if it exists) to ensure that $(EXTRATARGETS) is built first; in our environment that’s what we want since $(OBJDIR) depends on the results of that build. If your situation is different, you can omit or modify this line. However, _if_ there is a dependency between these two you must declare it. Otherwise, `make` might do the wrong thing, especially in the presence of a parallel build situation.

We add $(EXTRATARGETS) to the prerequisite line for the match-anything rule. In this case, since we declared the dependency relationship above, we could have omitted this and achieved the same result.

Finally, if $(EXTRATARGETS) exists we remove its contents during the `clean` rule. Remember that in this scenario the presence or absence of the `_common` directory is what notifies us that there is an extra target directory, so we must be careful not to remove the directory itself, only its contents. The `if`-statement will expand to an empty string if $(EXTRATARGETS) doesn’t exist.

Sample Implementation
---------------------

You can download a very small sample implementation of the above method [right here](http://make.mad-scientist.net/multi-example.tar.gz). Uncompress and untar the file, then change to the `example` directory and run `make`.

This trivial example merely transforms a `version.c.in` file into an `_common/version.c` file, using `sed` to install a version number. Then it creates an executable in the target directory:

```
example$ make
sed 's/@VERSION@/1.0/g' /tmp/example/version.c.in > version.c
cc /tmp/example/_common/version.c -o version

example$ ls _*
_Linux:
version

_common:
version.c

example$ _Linux/version
The version is `1.0'.
```

Now, if you override `OBJDIR` to have a different value you can see that `version.c` is not recreated, as it’s common between all the targets, but a new `version` binary is built:

```
example$ make OBJDIR=_Test
cc /tmp/example/_common/version.c -o version

example$ ls _*
_Linux:
version

_Test:
version

_common:
version.c

example$ _Test/version
The version is `1.0'.
```

*   When I was first developing this idea back in 1991/1992, I bounced a number of questions off of Roland McGrath: his responses were very helpful.
*   The enhancement for using $(MAKECMDGOALS) and the match-anything rule (instead of `.DEFAULT` as in the previous version of this document) was suggested to me via email by Jacob Burckhardt <bjacob@ca.metsci.com>. This also prodded me to revise and complete this document: when I wrote it originally $(MAKECMDGOALS) didn’t exist, and I wondered what other features added since the original version could be useful in this method.

Thanks to all!

<table><tbody><tr><th>1.00</th><td>18 August 2000</td><td>Revised.</td></tr><tr><th>0.10</th><td>???? 1997</td><td>Initial version posted; final sections still under construction.</td></tr></tbody></table>
