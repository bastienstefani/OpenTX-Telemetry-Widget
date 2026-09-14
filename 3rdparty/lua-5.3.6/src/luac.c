/*
** Minimal Lua 5.3 bytecode compiler for the Lua Telemetry build.
** Equivalent to "luac [-s] -o out.luac in.lua" from the official
** distribution (the listing/-l options are not needed here).
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

static int writer(lua_State *L, const void *p, size_t size, void *u) {
  (void)L;
  return (fwrite(p, size, 1, (FILE *)u) != 1) && (size != 0);
}

static int usage(const char *prog) {
  fprintf(stderr, "usage: %s [-s] [-o output] input.lua\n", prog);
  return EXIT_FAILURE;
}

int main(int argc, char **argv) {
  const char *output = "luac.out";
  const char *input = NULL;
  int strip = 0;
  int i;
  for (i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-s") == 0) strip = 1;
    else if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) output = argv[++i];
    else if (argv[i][0] == '-' && argv[i][1] != '\0') return usage(argv[0]);
    else input = argv[i];
  }
  if (input == NULL) return usage(argv[0]);
  lua_State *L = luaL_newstate();
  if (L == NULL) {
    fprintf(stderr, "%s: cannot create state\n", argv[0]);
    return EXIT_FAILURE;
  }
  if (luaL_loadfilex(L, input, "t") != LUA_OK) {
    fprintf(stderr, "%s: %s\n", argv[0], lua_tostring(L, -1));
    lua_close(L);
    return EXIT_FAILURE;
  }
  FILE *f = fopen(output, "wb");
  if (f == NULL) {
    fprintf(stderr, "%s: cannot open %s\n", argv[0], output);
    lua_close(L);
    return EXIT_FAILURE;
  }
  int err = lua_dump(L, writer, f, strip);
  if (ferror(f) || fclose(f) != 0 || err != 0) {
    fprintf(stderr, "%s: cannot write %s\n", argv[0], output);
    lua_close(L);
    return EXIT_FAILURE;
  }
  lua_close(L);
  return EXIT_SUCCESS;
}
