#EMACS_BUILDDIR := /home/tromey/Emacs/emacs

# STEP 1 (optional):
#
#   Uncomment the EMACS_BUILDDIR setting above if you want to include
#   souces from a local Emacs build.  NOTE that the 'dynamic-modules'
#   build option must be enabled (pass '--with-dynamic-modules' to the
#   'configure' script when building Emacs).

#SYS_INCLUDEDIRS := -I/usr/local/include

# STEP 2 (optional):
#
#   Construct a list of additional system libraries you want to
#   include. Each directory must have the string "-I" prepended to it.

INCLUDE_DIRS :=

EMACS = $(subst emacs is ,,$(shell type emacs))

ifdef EMACS_BULIDDIR
  INCLUDE_DIRS += -I$(EMACS_BUILDDIR)/src/ -I$(EMACS_BUILDDIR)/lib/
endif
ifdef SYS_INCLUDEDIRS
  ALL_INCLUDE_DIRS += $(SYS_INCLUDEDIRS)
endif

LDFLAGS = -shared
LIBS = -lffi -lltdl
CFLAGS += -g3 -Og -finline-small-functions -shared -fPIC

# Set this to debug make check.
#GDB = gdb --args

all: ffi-module.so ffi.elc

ffi-module.so: ffi-module.o
	$(CC) $(CFLAGS) $(ALL_INCLUDE_DIRS) $(LDFLAGS) -o ffi-module.so ffi-module.o $(LIBS)

ffi-module.o: ffi-module.c

EMACS_COMPILE_SCRIPT := ' \
	(add-to-list (quote dynamic-library-alist) "$(PWD)") \
  (module-load "ffi-module.so") \
  (byte-compile-file "./ffi.el") \
'

ffi.elc: ffi-module.so ffi.el
	$(EMACS) -Q --batch --eval=$(EMACS_COMPILE_SCRIPT);

check: ffi-module.so test.so
	LD_LIBRARY_PATH=`pwd`:$$LD_LIBRARY_PATH; \
	export LD_LIBRARY_PATH; \
	$(GDB) $(EMACS_BUILDDIR)/src/emacs -batch -L `pwd` -l ert -l test.el \
	  -f ert-run-tests-batch-and-exit

test.so: test.o
	$(CC) $(LDFLAGS) -o test.so test.o;

test.o: test.c

clean:
	rm -vf ffi-module.o ffi-module.so test.o test.so ffi.elc;
