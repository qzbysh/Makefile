# ------------------- usage --------------------------------
#        $ make D				# debug
#        $ make V				# verbose ouput
#        $ make DV or make VD	# debug verbose ouput
#        $ make d-VARNAME		# print-VARNAME
# ----------------------------------------------------------
.SUFFIXES:

# target executable file or .a or .so
TARGET := a
SRCDIR := 1
OBJDIR := _build
LDLIBS :=
LDFLAGS :=
CFLAGS = -Wall -Wextra -Wfatal-errors -std=c11
CXXFLAGS = -Wall -Wextra -Wfatal-errors -std=c++11


ifneq (,$(filter _%,$(notdir $(CURDIR))))


Q := @

V: Q :=
D: CFLAGS += -D DEBUG -g
D: CXXFLAGS +=  -D DEBUG -g
DV: Q :=
DV: CFLAGS += -D DEBUG -g
DV: CXXFLAGS +=  -D DEBUG -g
VD: Q :=
VD: CFLAGS += -D DEBUG -g
VD: CXXFLAGS +=  -D DEBUG -g
%.so: CFLAGS += -fPIC -shared
%.so: CXXFLAGS += -fPIC -shared

VPATH += $(SRCDIR)
SRC_C := $(notdir $(wildcard $(SRCDIR)/*.c))
SRC_CPP := $(notdir $(wildcard $(SRCDIR)/*.cpp))
OBJECTS = $(SRC_C:.c=.o) $(SRC_CPP:.cpp=.o)

CFLAGS += -MP -MMD $(patsubst %,-I%,$(subst :, ,$(VPATH)))
CXXFLAGS += -MP -MMD $(patsubst %,-I%,$(subst :, ,$(VPATH)))

TARGET_SUFFIX := $(suffix $(TARGET))
ifdef TARGET_SUFFIX
    TARGET_T := $(TARGET)
else
    TARGET_T := $(TARGET).out
endif


.SECONDARY: $(OBJECTS)
.PHONY: all V D DV VD

all: $(TARGET_T)

V D DV VD: all

# Create static library
%.a: $(OBJECTS)
	@ echo "Generating static lib file -> " $@
	$(Q) $(AR) cr $@ $^

# Create dynamic library
%.so: $(OBJECTS)
	@ echo "Generating dynamic lib file -> " $@
	$(Q) $(CXX) -fPIC -shared $(LDFLAGS) $^ $(LDLIBS) -o $@

# Generating executable file
%.out: $(OBJECTS)
	@ echo "Generating executable file -> " $*
	$(Q) $(CXX) $(LDFLAGS) $^ $(LDLIBS) -o $*

%.o: %.c
	@ echo "Compiling: $< -> $(BUILD_DIR)/$@"
	$(Q) $(CC) $(CFLAGS) -c -o $@  $<
%.o: %.cpp
	@ echo "Compiling: $< -> $(BUILD_DIR)/$@"
	$(Q) $(CXX) $(CXXFLAGS) -c -o $@ $<

d-%::
	@ echo '$*=(*)'
	@ echo '	origin = $(origin *)'
	@ echo '	flavor = $(flavor *)'
	@ echo '		value = $(value  $*)'


else


.PHONY: $(OBJDIR)
$(OBJDIR) :
	+@[ -d $@ ] || mkdir -p $@
	+@$(MAKE) --no-print-directory -C $@ -f $(CURDIR)/Makefile SRCDIR=$(CURDIR)/$(SRCDIR) $(MAKECMDGOALS)

Makefile : ;
%.mk :: ;

% :: $(OBJDIR) ;


endif


.PHONY: run
run:
	@ PATH="./:$(CURDIR)/$(OBJDIR)"; $(TARGET) || true

.PHONY: install
install:
	@ echo "install: $(OBJDIR)$(TARGET) -> ../bin/$(TARGET)"
	@ install -Ds -t ../bin $(OBJDIR)$(TARGET)

.PHONY: clean
clean: 
	@ echo "Clear build directory of $(TARGET)"
	@ $(RM) -r $(OBJDIR)


# Add dependency files, if they exist
-include $(OBJECTS:.o=.d)
