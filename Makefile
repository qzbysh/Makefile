# ------------------- usage --------------------------------
#  make d=y				# debug
#  make v=y				# verbose ouput
#  make d-VARNAME		# print-VARNAME
#  TARGET: exe:*, static library:*.a, dynamic library:*.so
# ----------------------------------------------------------


# ------------------- conf ---------------------------------
TARGET   := test
VPATH    := .
OBJDIR   := _build
LDLIBS   :=
LDFLAGS  :=
CFLAGS   := -Wall -Wextra -Wfatal-errors -std=c11
CXXFLAGS := -Wall -Wextra -Wfatal-errors -std=c++11
# ------------------- conf end -----------------------------


TOP      ?= $(CURDIR)
VPATH    := $(abspath $(addprefix $(TOP)/, $(VPATH)))
LDFLAGS  := $(subst -L, -L$(TOP)/, $(LDFLAGS))
LDFLAGS  += $(addprefix -L, $(VPATH))
CFLAGS   += -MP -MMD $(patsubst %,-I%,$(subst :, , $(VPATH)))
CXXFLAGS += -MP -MMD $(patsubst %,-I%,$(subst :, , $(VPATH)))
SRC_C    := $(notdir $(wildcard $(addsuffix /*.c, $(VPATH))))
SRC_CPP  := $(notdir $(wildcard $(addsuffix /*.cpp, $(VPATH))))
OBJECTS  := $(SRC_C:.c=.o) $(SRC_CPP:.cpp=.o)

%.so: CFLAGS   += -fPIC -shared
%.so: CXXFLAGS += -fPIC -shared


ifneq ($(v), y)
    Q := @
endif

ifeq ($(d), y)
    CFLAGS   += -D DEBUG -g
    CXXFLAGS += -D DEBUG -g
endif

ifeq ($(suffix $(TARGET)),)
    TARGET_T := $(TARGET).out
else
    TARGET_T := $(TARGET)
endif


.PHONY: $(OBJDIR) all run install clean
.SECONDARY: $(OBJECTS)

ifeq ($(filter _%,$(notdir $(CURDIR))),)
$(OBJDIR):
	+@[ -d $@ ] || mkdir -p $@
	+@$(MAKE) -C $@ -r --no-print-directory -f $(CURDIR)/Makefile TOP=$(CURDIR) $(MAKEOVERRIDES)
endif

all: $(TARGET_T)

%.a: $(OBJECTS)
	@ echo "Generating static lib file -> " $@
	$(Q) $(AR) cr $@ $^

%.so: $(OBJECTS)
	@ echo "Generating dynamic lib file -> " $@
	$(Q) $(CXX) -fPIC -shared $(LDFLAGS) $(LDLIBS) $^ -o $@

%.out: $(OBJECTS)
	@ echo "Generating executable file -> " $*
	$(Q) $(CXX) $(LDFLAGS) $(LDLIBS) $^ -o $*

%.o: %.c
	@ echo "Compiling: $< -> $(BUILD_DIR)/$@"
	$(Q) $(CC) $(CFLAGS) -c -o $@  $<

%.o: %.cpp
	@ echo "Compiling: $< -> $(BUILD_DIR)/$@"
	$(Q) $(CXX) $(CXXFLAGS) -c -o $@ $<

run:
	$(Q) $(CURDIR)/$(OBJDIR)/$(TARGET)

install:
	@ echo "install: $(OBJDIR)/$(TARGET) -> ../lib/$(TARGET)"
	$(Q) install -Ds -t ../lib $(OBJDIR)/$(TARGET)

clean:
	@ echo "Clear build directory of $(TARGET)"
	$(Q) $(RM) -r $(OBJDIR)

d-%::
	$(Q) echo '$*=(*)'
	$(Q) echo '    origin = $(origin *)'
	$(Q) echo '    flavor = $(flavor *)'
	$(Q) echo '        value = $(value  $*)'


# Add dependency files, if they exist
-include $(OBJECTS:.o=.d)
