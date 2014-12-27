#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int main(int argc, char *argv[]) {
    int i;
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    lua_newtable(L);
    for (i = 0; i < argc; i++) {
        lua_pushnumber(L, i);
        lua_pushstring(L, argv[i]);
        lua_rawset(L, -3);
    }
    lua_setglobal(L, "arg");

    char *cmd = "require('luacmd')";
    int status = luaL_loadbuffer(L, cmd, strlen(cmd), "=bootstrap");
    lua_call(L, 0, LUA_MULTRET);

    lua_close(L);
    return 0;
}
