cmake_minimum_required(VERSION 2.8)
project(luacmd)

FUNCTION(PREPEND var prefix)
   SET(listVar "")
   FOREACH(f ${ARGN})
      LIST(APPEND listVar "${prefix}/${f}")
   ENDFOREACH(f)
   SET(${var} "${listVar}" PARENT_SCOPE)
ENDFUNCTION(PREPEND)

set (CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

option(LUA_USE_LUAJIT "Use LuaJIT instead of default Lua" ON)
unset(Lua_FOUND CACHE)
unset(LUA_INCLUDE_DIR CACHE)
unset(LUA_LIBRARY CACHE)
find_package(Lua REQUIRED)

find_package(PCRE REQUIRED)

set(LUA_FILES src/inspect.lua src/boot.lua src/main.lua)
prepend(LUA_FILES_DIR ${CMAKE_CURRENT_SOURCE_DIR} ${LUA_FILES})

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/luacmd.o
    COMMAND ${LUA_BINARY} ${CMAKE_CURRENT_SOURCE_DIR}/tools/combiner.lua ${LUA_FILES_DIR} > ${CMAKE_CURRENT_BINARY_DIR}/luacmd.lua
    COMMAND ${LUA_BINARY} -b -n luacmd ${CMAKE_CURRENT_BINARY_DIR}/luacmd.lua ${CMAKE_CURRENT_BINARY_DIR}/luacmd.o
)

include_directories(${LUA_INCLUDE_DIR})
add_executable(luacmd src/main.c ${CMAKE_CURRENT_BINARY_DIR}/luacmd.o)
target_link_libraries(luacmd
    ${CMAKE_DL_LIBS} ${LUA_LIBRARY} ${PCRE_PCRE_LIBRARY})
set_target_properties(luacmd PROPERTIES
    ENABLE_EXPORTS true)

install(PROGRAMS ${CMAKE_BINARY_DIR}/luacmd DESTINATION bin)

add_custom_target(test
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/DESIGN DESIGN
    COMMAND chmod a+x ${CMAKE_CURRENT_BINARY_DIR}/luacmd
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/runtests.sh ${CMAKE_CURRENT_BINARY_DIR}/luacmd
)
