cmake_minimum_required(VERSION 2.8)
project(luacmd)

set (CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

option(LUA_USE_LUAJIT "Use LuaJIT instead of default Lua" ON)
unset(Lua_FOUND CACHE)
unset(LUA_INCLUDE_DIR CACHE)
unset(LUA_LIBRARY CACHE)
find_package(Lua REQUIRED)

find_package(PCRE REQUIRED)

set(LUAOBJS boot.o inspect.o)

add_executable(luacmd src/main.c ${LUAOBJS} ${REGEX_SOURCES})

add_custom_command(
    OUTPUT boot.o inspect.o
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/src/boot.lua boot.lua
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/src/inspect.lua inspect.lua
    COMMAND luajit -b boot.lua boot.o
    COMMAND luajit -b inspect.lua inspect.o
)

include_directories(${LUA_INCLUDE_DIR})
target_link_libraries(luacmd 
    ${CMAKE_DL_LIBS} ${LUA_LIBRARY} ${PCRE_PCRE_LIBRARY})
set_target_properties(luacmd PROPERTIES ENABLE_EXPORTS true)

add_custom_target(test
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/DESIGN DESIGN
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/runtests.sh ${CMAKE_CURRENT_BINARY_DIR}/luacmd
)
