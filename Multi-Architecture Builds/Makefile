# This is a sample "general Makefile", showing how a two-step architecture
# invocation might be written.
#
# This file first jumps into the _common architecture directory and
# constructs a "version.h" file from the source version.h.in, which merely
# replaces a string with the proper version number.
#
# Then, it jumps to the architecture-specific directory and builds a program
# that prints that version (very trivial, I know, but it should demonstrate
# the salient points.
#

ifeq (,$(filter _%,$(notdir $(CURDIR))))
  include target.mk
else
#----- End Boilerplate

  # This section is common to both target directories

  VPATH	  = $(SRCDIR)

  VERSION = 1.0

  all::
  .PHONY: all

ifeq (_common,$(notdir $(CURDIR)))

  # This section is for the _common target directory

  .SUFFIXES:
  .DEFAULT: ; @:

  all:: version.c ; @:

  version.c: version.c.in
	sed 's/@VERSION@/$(VERSION)/g' $< > $@

else

  # This section is for the architecture-specific target directory

  VPATH +=  $(SRCDIR)/_common

  all:: version

#----- Begin Boilerplate
endif
endif
