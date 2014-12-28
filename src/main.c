#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <luajit.h>

LUALIB_API int luaopen_librex(lua_State *L);

int main(int argc, char *argv[]) {
    int i;
    char *cmd;
    int status;
    lua_State *L = lua_open();
    if (L == NULL) {
        printf("cannot create state: not enough memory\n");
        return EXIT_FAILURE;
    }
    LUAJIT_VERSION_SYM();  /* linker-enforced version check */
    luaL_openlibs(L);

    // Load librex (lrexlib-pcre) into 're' global
    lua_pushstring(L, "re");
    lua_pushcfunction(L, luaopen_librex);
    lua_pushstring(L, "librex");
    lua_call(L, 1, 1);
    lua_rawset(L, LUA_GLOBALSINDEX);

    // Setup command line arguments
    lua_newtable(L);
    for (i = 0; i < argc; i++) {
        lua_pushnumber(L, i);
        lua_pushstring(L, argv[i]);
        lua_rawset(L, -3);
    }
    lua_setglobal(L, "arg");

    cmd = "require('luacmd')";
    status = luaL_loadbuffer(L, cmd, strlen(cmd), "=bootstrap");
    lua_call(L, 0, LUA_MULTRET);

    lua_close(L);
    return 0;
}
