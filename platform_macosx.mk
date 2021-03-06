# Copyright (c) 2012 Turbulenz Limited.
# Released under "Modified BSD License".  See COPYING for full text.

############################################################

ifeq (1,$(MACOSX_USE_OLD_TOOLS))
  MACOSX_XCODE_BIN_PATH := $(wildcard /Developer/usr/bin/)
endif

ifneq (,$(MACOSX_XCODE_BIN_PATH))
  # OLD TOOLS
  MACOSX_CXX := llvm-g++-4.2
  CXXFLAGS += -ftree-vectorize
  CMMFLAGS += -ftree-vectorize
else
  # clang
  MACOSX_CXX := clang
  CXXFLAGS += -stdlib=libc++ -Wno-c++11-extensions -Wno-c++11-long-long
  CMMFLAGS += -stdlib=libc++ -Wno-c++11-extensions -Wno-c++11-long-long
  MACOSX_LDFLAGS += -lc++
  MACOSX_DLLFLAGS += -lc++
endif

# Language to compile all .cpp files as
MACOSX_CXX_DEFAULTLANG ?= objective-c++

XCODE_SDK_VER ?= 10.9

# Mark builds that are linked against the non-default SDKs

ifneq ($(XCODE_SDK_VER),10.9)
  VARIANT:=$(strip $(VARIANT)-$(XCODE_SDK_VER))
endif

# Check the known SDK install locations

XCODE_SDK_ROOT:=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX$(XCODE_SDK_VER).sdk
ifeq (,$(wildcard $(XCODE_SDK_ROOT)))
  XCODE_SDK_ROOT:=/Developer/SDKs/MacOSX$(XCODE_SDK_VER).sdk
endif

############################################################

$(call log,MACOSX BUILD CONFIGURATION)

#
# CXX / CMM FLAGS
#

CXX := $(MACOSX_XCODE_BIN_PATH)$(MACOSX_CXX)
CMM := $(CXX)

CXXFLAGSPRE := -x $(MACOSX_CXX_DEFAULTLANG) \
    -arch i386 -fmessage-length=0 -pipe -fno-exceptions \
    -fpascal-strings -fasm-blocks \
    -fstrict-aliasing -fno-threadsafe-statics \
    -msse3 -mssse3 \
    -Wall -Wno-unknown-pragmas -Wno-overloaded-virtual \
    -Wno-reorder -Wno-trigraphs -Wno-unused-parameter \
    -isysroot $(XCODE_SDK_ROOT) \
    -mmacosx-version-min=$(XCODE_SDK_VER) \
    -fvisibility-inlines-hidden \
    -fvisibility=hidden \
    -DXP_MACOSX=1 -DMACOSX=1

# -fno-rtti
# -fno-exceptions
# -fvisibility=hidden

CMMFLAGSPRE := -x objective-c++ \
    -arch i386 -fmessage-length=0 -pipe -fno-exceptions \
    -fpascal-strings -fasm-blocks \
    -fstrict-aliasing -fno-threadsafe-statics \
    -msse3 -mssse3 \
    -Wall -Wno-unknown-pragmas -Wno-overloaded-virtual \
    -Wno-reorder -Wno-trigraphs -Wno-unused-parameter \
    -Wno-undeclared-selector \
    -isysroot $(XCODE_SDK_ROOT) \
    -mmacosx-version-min=$(XCODE_SDK_VER) \
    -fvisibility-inlines-hidden \
    -fvisibility=hidden \
    -DXP_MACOSX=1 -DMACOSX=1

# -fno-exceptions
# -fno-rtti

CXXFLAGSPOST := \
    -c

CMMFLAGSPOST := \
    -c

# DEBUG / RELEASE

ifeq ($(CONFIG),debug)
  CXXFLAGSPRE += -g -O0 -D_DEBUG -DDEBUG
  CMMFLAGSPRE += -g -O0 -D_DEBUG -DDEBUG
else
  CXXFLAGSPRE += -g -O3 -DNDEBUG
  CMMFLAGSPRE += -g -O3 -DNDEBUG
endif

#
# LIBS
#

# ARFLAGSPOST := \
#     -Xlinker \
#     --no-demangle \
#     -framework CoreFoundation \
#     -framework OpenGL \
#     -framework Carbon \
#     -framework AGL \
#     -framework QuartzCore \
#     -framework AppKit \
#     -framework IOKit \
#     -framework System

AR := MACOSX_DEPLOYMENT_TARGET=$(XCODE_SDK_VER) $(MACOSX_XCODE_BIN_PATH)libtool
ARFLAGSPRE := -static -arch_only i386 -g
arout := -o
ARFLAGSPOST := \
  -framework CoreFoundation \
  -framework OpenGL \
  -framework Carbon \
  -framework AGL \
  -framework QuartzCore \
  -framework AppKit \
  -framework IOKit \
  -framework System

libprefix := lib
libsuffix := .a

#
# DLL
#

DLL := MACOSX_DEPLOYMENT_TARGET=$(XCODE_SDK_VER) $(MACOSX_XCODE_BIN_PATH)$(MACOSX_CXX)
DLLFLAGSPRE := \
  -isysroot $(XCODE_SDK_ROOT) -dynamiclib -arch i386 -g $(MACOSX_DLLFLAGS)
DLLFLAGSPOST := \
  -framework CoreFoundation \
  -framework OpenGL \
  -framework Carbon \
  -framework AGL \
  -framework QuartzCore \
  -framework AppKit \
  -framework IOKit \
  -framework System

DLLFLAGS_LIBDIR := -L
DLLFLAGS_LIB := -l

dllprefix :=
dllsuffix := .dylib

dll-post = \
  $(CMDPREFIX) for d in $($(1)_ext_dlls) ; do \
    in=`$(MACOSX_XCODE_BIN_PATH)otool -D $$$$d | grep -v :`; \
    bn=`basename $$$$d`; \
    $(MACOSX_XCODE_BIN_PATH)install_name_tool -change $$$$in @loader_path/$$$$bn $$@ ; \
  done

#
# APPS
#

LDFLAGS_LIBDIR := -L
LDFLAGS_LIB := -l

LD := $(MACOSX_XCODE_BIN_PATH)$(MACOSX_CXX)
LDFLAGSPRE := \
    -arch i386 \
    -g \
    -isysroot $(XCODE_SDK_ROOT) \
    $(MACOSX_LDFLAGS)

LDFLAGSPOST := \
    -mmacosx-version-min=$(XCODE_SDK_VER) \
    -dead_strip \
    -Wl,-search_paths_first \
    -framework CoreFoundation \
    -framework OpenGL \
    -framework Carbon \
    -framework QuartzCore \
    -framework AppKit \
    -framework IOKit \
    -licucore

#    -Xlinker \
#    --no-demangle \

app-post = \
  $(CMDPREFIX) for d in $($(1)_ext_dlls) ; do \
    in=`$(MACOSX_XCODE_BIN_PATH)otool -D $$$$d | grep -v :`; \
    bn=`basename $$$$d`; \
    $(MACOSX_XCODE_BIN_PATH)install_name_tool -change $$$$in @loader_path/$$$$bn $$@ ; \
  done

############################################################
