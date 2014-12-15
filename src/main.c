/*
** Perlesque alternate LuaJIT interpreter frontend.
**
** Major portions taken verbatim from original LuaJIT interpreter.
** Copyright (C) 2005-2014 Mike Pall. See Copyright Notice in luajit.h
**
** Major portions taken verbatim or adapted from the Lua interpreter.
** Copyright (C) 1994-2008 Lua.org, PUC-Rio. See Copyright Notice in lua.h
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdbool.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <luajit.h>

#define MAXBUF (4096)

static const char *progname = "luacmd";

/* Output an error message back to user on stderr */
static void l_message(const char *pname, const char *msg)
{
  if (pname) fprintf(stderr, "%s: ", pname);
  fprintf(stderr, "%s\n", msg);
  fflush(stderr);
}

/* Get return value of Lua chunk */
static int report(lua_State *L, int status)
{
  if (status && !lua_isnil(L, -1)) {
    const char *msg = lua_tostring(L, -1);
    if (msg == NULL) msg = "(error object is not a string)";
    l_message(progname, msg);
    lua_pop(L, 1);
  }
  return status;
}

/* Error stack backtrace */
static int traceback(lua_State *L)
{
  if (!lua_isstring(L, 1)) { /* Non-string error object? Try metamethod. */
    if (lua_isnoneornil(L, 1) ||
	!luaL_callmeta(L, 1, "__tostring") ||
	!lua_isstring(L, -1))
      return 1;  /* Return non-string error object. */
    lua_remove(L, 1);  /* Replace object by result of __tostring metamethod. */
  }
  luaL_traceback(L, L, lua_tostring(L, 1), 1);
  return 1;
}


/* Call Lua chunk */
static int docall(lua_State *L, int narg, int clear)
{
  int status;
  int base = lua_gettop(L) - narg;  /* function index */
  lua_pushcfunction(L, traceback);  /* push traceback function */
  lua_insert(L, base);  /* put it under chunk and args */
  status = lua_pcall(L, narg, (clear ? 0 : LUA_MULTRET), base);
  lua_remove(L, base);  /* remove traceback function */
  /* force a complete garbage collection in case of errors */
  if (status != 0) lua_gc(L, LUA_GCCOLLECT, 0);
  return status;
}

/* Append modules/?.lua to module search path */

static int dostring(lua_State *L, const char *s, const char *name)
{
  int status = luaL_loadbuffer(L, s, strlen(s), name) || docall(L, 0, 1);
  return report(L, status);
}


/** MAIN **/
int main(int argc, char *argv[]) {
    int status;
    lua_State *L = lua_open();  /* create state */
    if (L == NULL) {
        l_message(argv[0], "cannot create state: not enough memory");
        return EXIT_FAILURE;
    }
    LUAJIT_VERSION_SYM();  /* linker-enforced version check */
    lua_gc(L, LUA_GCSTOP, 0);  /* stop collector during initialization */
    luaL_openlibs(L);  /* open libraries */
    dostring(L, "re=require('rex_pcre');\n", "header");
    dostring(L, "inspect=require('inspect');\n", "header");
    lua_gc(L, LUA_GCRESTART, -1);
    // Go through options
    int i = 1;
    bool lines = false;
    bool autosplit = false;
    char irs = '\n';
    char crs = '\t';
    while (i < argc) {
        if (argv[i][0] == '-') {
            if (argv[i][1] == 'e') {
                if (i < argc) {
                    i++;
                    if (lines) {
                        char buf[MAXBUF];
                        snprintf(buf, MAXBUF, "for _ in io.lines() do\n%s\nend\nif final then final() end\n", argv[i]);
                        dostring(L, buf, "expression");
                    } else {
                        dostring(L, argv[i], "expression");
                    }
                    i++;
                    continue;                    
                } else {
                    l_message(argv[0], "Illegal argument");
                    goto cleanup;
                }
            }
            if (argv[i][1] == 'n') {
                lines = true;
                i++;
                continue;
            }
            if (argv[i][1] == 'a') {
                autosplit = true;
                i++;
                continue;
            }
        }
cleanup:
        l_message(argv[0], "Illegal argument");
        lua_close(L);
        return EXIT_FAILURE;
    }
    lua_close(L);
    return EXIT_SUCCESS;
}
