# usage: 
#        $ make
#        $ make v=y	# verbose ouput
#        $ make d=y	# debug


# target executable file or .a or .so or .out
TARGET := a.out

# Add additional include paths
INCLUDES := -I. -I../include

# Extra flags to give to compilers when they are supposed to invoke the linker,
# ‘ld’, such as -L. Libraries (-lfoo) should be added to the LDLIBS variable instead. 
LDFLAGS := -Wl,-rpath,'$$ORIGIN'

# Library flags or names given to compilers when they are supposed to invoke the linker, 
# ‘ld’. LOADLIBES is a deprecated (but still supported) alternative to LDLIBS. 
# Non-library linker flags, such as -L, should go in the LDFLAGS variable. 
LDLIBS :=

# General compiler flags
CFLAGS = -std=c11
CXXFLAGS = -std=c++11

# Path to the source directory, relative to the makefile
SRC_DIR = 

# Build and output paths
BUILD_DIR = build/

# Search Path for All Prerequisites
VPATH := 

# Compiler used
CC := gcc
CXX := g++
ARFLAGS := cr


.SECONDARY:


ifeq ($(v), y)
    Q  =
else
    Q  = @
endif


ifeq ($(d), y)
    CFLAGS += -Wall -Wextra -Wfatal-errors -D DEBUG  -g
    CXXFLAGS += -Wall -Wextra -Wfatal-errors -D DEBUG  -g
else
    CFLAGS += -Wall -Wextra -Wfatal-errors -D NDEBUG -O3
    CXXFLAGS += -Wall -Wextra -Wfatal-errors -D NDEBUG -O3
endif


$(BUILD_DIR)%.so: CFLAGS += -fPIC -shared
$(BUILD_DIR)%.so: CXXFLAGS += -fPIC -shared

VPATH := $(SRC_DIR) $(BUILD_DIR)


# Set the object file names, with the source directory stripped
# from the path, and the build path prepended in its place
OBJECTS := $(patsubst $(SRC_DIR)%.c,$(BUILD_DIR)%.o, $(wildcard $(SRC_DIR)*.c))
OBJECTS += $(patsubst $(SRC_DIR)%.cpp,$(BUILD_DIR)%.o, $(wildcard $(SRC_DIR)*.cpp))

# Set the dependency files that will be used to add header dependencies
DEPS := $(OBJECTS:.o=.d)


all: $(BUILD_DIR)$(TARGET)

run:
	$(Q)PATH="../bin:./:$(BUILD_DIR) "; $(TARGET) || true
.PHONY: run


install:
	$(Q)echo "install: $(BUILD_DIR)$(TARGET) -> ../bin/$(TARGET)"
	$(Q)install -Ds -t ../bin $(BUILD_DIR)$(TARGET)
.PHONY: install


# Removes all build files
clean: 
	$(Q)echo "Clear build directory of $(TARGET)"
	$(Q)$(RM) -r $(BUILD_DIR)
.PHONY: clean

$(BUILD_DIR):
	$(Q) mkdir -p $@ 


# Function used to check variables. Use on the command line:
# make print-VARNAME
# Useful for debugging and adding features
d-%::
	$(Q)echo '$*=(*)'
	$(Q)echo '	origin = $(origin *)'
	$(Q)echo '	flavor = $(flavor *)'
	$(Q)echo '		value = $(value  $*)'


# Create static library
$(BUILD_DIR)%.a: $(OBJECTS)
	$(Q)echo "Generating static lib file -> " $@
	$(Q)$(AR) $(ARFLAGS) $@ $^


# Create dynamic library
$(BUILD_DIR)%.so: $(OBJECTS)
	$(Q)echo "Generating dynamic lib file -> " $@
	$(Q)$(CXX) -fPIC -shared $^ -o $@ $(LDFLAGS)  $(LDLIBS)


# Generating executable file
$(BUILD_DIR)%.out: $(OBJECTS)
	$(Q)echo "Generating executable file -> " $@
	$(Q)$(CXX) $^ -o $@ $(LDFLAGS) $(LDLIBS)


# Source file rules
# After the first compilation they will be joined with the rules from the
# dependency files to provide header dependencies
$(BUILD_DIR)%.o: %.c | $(BUILD_DIR)
	$(Q)echo "Compiling: $< -> $@"
	$(Q)$(CC) $(CFLAGS) $(INCLUDES) -MP -MMD -c $< -o $@

$(BUILD_DIR)%.o: %.cpp | $(BUILD_DIR)
	$(Q)echo "Compiling: $< -> $@"
	$(Q)$(CXX) $(CXXFLAGS) $(INCLUDES) -MP -MMD -c $< -o $@


# Add dependency files, if they exist
-include $(DEPS)
