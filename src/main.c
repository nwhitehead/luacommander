/*
** Perl-esque alternate LuaJIT interpreter frontend.
**
** Portions taken verbatim from original LuaJIT interpreter.
** Copyright (C) 2005-2014 Mike Pall. See Copyright Notice in luajit.h
**
** Portions taken verbatim or adapted from the Lua interpreter.
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
static int traceback(lua_State *L) {
    if (!lua_isstring(L, 1)) {
        // Non-string error object? Try metamethod.
        if (lua_isnoneornil(L, 1) ||
            !luaL_callmeta(L, 1, "__tostring") ||
            !lua_isstring(L, -1)) {
            // Return the non-string error object.
            return 1;
        }
        // Replace object by result of __tostring metamethod.
        lua_remove(L, 1);
    }
    luaL_traceback(L, L, lua_tostring(L, 1), 1);
    return 1;
}

/* Call Lua chunk */
static int docall(lua_State *L, int narg, int clear) {
    int status;
    int base = lua_gettop(L) - narg;
    // Push traceback under other args
    lua_pushcfunction(L, traceback);
    lua_insert(L, base);
    status = lua_pcall(L, narg, (clear ? 0 : LUA_MULTRET), base);
    // Remove traceback function
    lua_remove(L, base);
    // force a complete garbage collection in case of errors
    if (status != 0) lua_gc(L, LUA_GCCOLLECT, 0);
    return status;
}

/* Eval a string directly */
static int dostring(lua_State *L, const char *s, const char *name) {
    int status = luaL_loadbuffer(L, s, strlen(s), name) || docall(L, 0, 1);
    return report(L, status);
}

/* Handle -e option */
static void handleexpr(lua_State *L, bool lines, bool printit, char *irs, char *crs,
                       char *expr, char *exprEnd) {
    int status;
    lua_getglobal(L, "__process");
    char buf[MAXBUF];
    if (expr) {
        snprintf(buf, MAXBUF, "return function(_, _F) %s end\n", expr);
        status = luaL_loadbuffer(L, buf, strlen(buf), "expression");
        report(L, status);
        if (status) return;
        status = docall(L, 0, 0);
        report(L, status);
        if (status) return;
    } else {
        lua_pushnil(L);
    }
    if (exprEnd) {
        snprintf(buf, MAXBUF, "return function(_, _F) %s end\n", exprEnd);
        status = luaL_loadbuffer(L, buf, strlen(buf), "expressionEnd");
        report(L, status);
        if (status) return;
        status = docall(L, 0, 0);
        report(L, status);
        if (status) return;
    } else {
        lua_pushnil(L);
    }
    lua_pushboolean(L, lines);
    lua_pushboolean(L, printit);
    lua_pushstring(L, irs);
    lua_pushstring(L, crs);
    status = docall(L, 6, 0);
    report(L, status);
    if (status) return;
}

/** MAIN **/
int main(int argc, char *argv[]) {
    int status;
    lua_State *L = lua_open();  /* create state */
    if (L == NULL) {
        l_message(argv[0], "cannot create state: not enough memory");
        return EXIT_FAILURE;
    }
    // Linker enforced version check
    LUAJIT_VERSION_SYM();
    // Stop GC during initialization
    lua_gc(L, LUA_GCSTOP, 0);
    // Open standard libraries
    luaL_openlibs(L);
    // Start bootstrap code
    dostring(L, "require('boot')\n", "boot");
    // Turn GC back on
    lua_gc(L, LUA_GCRESTART, -1);
    // Go through options
    int i = 1;
    bool lines = false;
    bool printit = false;
    char *irs = NULL;
    char *crs = NULL;
    char *expr = NULL;
    char *exprEnd = NULL;
    while (i < argc) {
        if (argv[i][0] == '-') {
            if (argv[i][1] == 'e') {
                if (i < argc) {
                    i++;
                    expr = argv[i];
                    i++;
                    continue;                    
                } else {
                    l_message(argv[0], "No expression to evaluate for -e");
                    goto cleanup;
                }
            }
            if (argv[i][1] == 'z') {
                i++;
                exprEnd = argv[i];
                i++;
                continue;
            }
            if (argv[i][1] == 'n') {
                lines = true;
                i++;
                continue;
            }
            if (argv[i][1] == 'p') {
                printit = true;
                i++;
                continue;
            }
            if (argv[i][1] == 'L') {
                i++;
                irs = argv[i];
                i++;
                continue;
            }
            if (argv[i][1] == 'F') {
                i++;
                crs = argv[i];
                i++;
                continue;
            }
            if (argv[i][1] == 'I') {
                i++;
                irs = argv[i];
                i++;
                continue;
            }
        }
cleanup:
        l_message(argv[0], "Illegal argument");
        lua_close(L);
        return EXIT_FAILURE;
    }
    // Check for some illegal option combinations
    if (exprEnd && !lines) {
        l_message(argv[0], "Final expression without -n option is illegal");
        lua_close(L);
        return EXIT_FAILURE;        
    }
    if (expr || exprEnd) {
        // Evaluate expression
        handleexpr(L, lines, printit, irs, crs, expr, exprEnd);
    } else {
        l_message(argv[0], "No expression to evaluation");
        lua_close(L);
        return EXIT_FAILURE;
    }
    lua_close(L);
    return EXIT_SUCCESS;
}
