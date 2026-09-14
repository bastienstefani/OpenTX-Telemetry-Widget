# Makefile for building the Lua 5.3.6 interpreter and bytecode compiler used to
# produce EdgeTX 2.11+ / 3.x compatible .luac files.
#
# EdgeTX builds Lua with LUA_32BITS (32-bit integers and floats),
# LUA_COMPAT_5_2 and LUA_FLOORN2I=1, and stores a 4-byte size_t in the bytecode
# header (see ldump.c / lundump.c). The same options are used here so that the
# bytecode header and number formats match the radio.

CC= gcc -std=gnu99
CFLAGS= -O2 -Wall -Wextra -DLUA_COMPAT_5_2 -DLUA_32BITS -DLUA_FLOORN2I=1 $(SYSCFLAGS) $(MYCFLAGS)
LDFLAGS= $(SYSLDFLAGS) $(MYLDFLAGS)
LIBS= -lm $(SYSLIBS) $(MYLIBS)

AR= ar rcu
RANLIB= ranlib
RM= rm -f

SYSCFLAGS=
SYSLDFLAGS=
SYSLIBS=

MYCFLAGS=
MYLDFLAGS=
MYLIBS=

CORE_O=	lapi.o lcode.o lctype.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o \
	lmem.o lobject.o lopcodes.o lparser.o lstate.o lstring.o ltable.o \
	ltm.o lundump.o lvm.o lzio.o
LIB_O=	lauxlib.o lbaselib.o lbitlib.o lcorolib.o ldblib.o liolib.o \
	lmathlib.o loslib.o lstrlib.o ltablib.o lutf8lib.o loadlib.o linit.o
BASE_O= $(CORE_O) $(LIB_O)

LUA_A=	liblua.a
LUA_T=	lua
LUA_O=	lua.o
LUAC_T=	luac
LUAC_O=	luac.o

ALL_T= $(LUA_A) $(LUA_T) $(LUAC_T)

default: generic

all: $(ALL_T)

generic: all

$(LUA_A): $(BASE_O)
	$(AR) $@ $(BASE_O)
	$(RANLIB) $@

$(LUA_T): $(LUA_O) $(LUA_A)
	$(CC) -o $@ $(LDFLAGS) $(LUA_O) $(LUA_A) $(LIBS)

$(LUAC_T): $(LUAC_O) $(LUA_A)
	$(CC) -o $@ $(LDFLAGS) $(LUAC_O) $(LUA_A) $(LIBS)

clean:
	$(RM) $(ALL_T) $(BASE_O) $(LUA_O) $(LUAC_O)

.c.o:
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: all default generic clean
