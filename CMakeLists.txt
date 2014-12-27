cmake_minimum_required(VERSION 2.8)

project(luacmd)
include(ExternalProject)

FUNCTION(PREPEND var prefix)
   SET(listVar "")
   FOREACH(f ${ARGN})
      LIST(APPEND listVar "${prefix}/${f}")
   ENDFOREACH(f)
   SET(${var} "${listVar}" PARENT_SCOPE)
ENDFUNCTION(PREPEND)

set (CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(PCRE REQUIRED)

ExternalProject_Add(project_luajit
  URL http://luajit.org/download/LuaJIT-2.0.3.tar.gz
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/luajit-2.0.3
  CONFIGURE_COMMAND ""
  BUILD_IN_SOURCE 1
  BUILD_COMMAND make -j8
  INSTALL_COMMAND make install PREFIX=${CMAKE_CURRENT_BINARY_DIR}/luajit-2.0.3
)
ExternalProject_Get_Property(project_luajit install_dir)
ExternalProject_Get_Property(project_luajit source_dir)
add_library(luajit STATIC IMPORTED)
set_property(TARGET luajit PROPERTY IMPORTED_LOCATION ${install_dir}/lib/libluajit.a)
add_dependencies(luajit project_luajit)
set(LUA_INCLUDE_DIR ${install_dir}/include/luajit-2.0)
set(LUA_BINARY ${install_dir}/bin/luajit-2.0.3)
set(LUA_LIBRARY ${install_dir}/lib/libluajit-5.1.a)

set(LUA_FILES src/inspect.lua src/boot.lua src/main.lua)
prepend(LUA_FILES_DIR ${CMAKE_CURRENT_SOURCE_DIR} ${LUA_FILES})

add_custom_command(
    DEPENDS project_luajit
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/luacmd.c
    COMMAND ${LUA_BINARY} ${CMAKE_CURRENT_SOURCE_DIR}/tools/combiner.lua ${LUA_FILES_DIR} > ${CMAKE_CURRENT_BINARY_DIR}/luacmd.lua
    COMMAND ${LUA_BINARY} -b -n luacmd ${CMAKE_CURRENT_BINARY_DIR}/luacmd.lua ${CMAKE_CURRENT_BINARY_DIR}/luacmd.c
)

include_directories(${LUA_INCLUDE_DIR})
set(LREX_SRC
    external/lrexlib/src/common.c
    external/lrexlib/src/pcre/lpcre.c
    external/lrexlib/src/pcre/lpcre_f.c
)
add_definitions(-DVERSION=\"2.7.1\")
add_definitions(-DREX_OPENLIB=luaopen_librex)
add_library(rex STATIC ${LREX_SRC})
target_link_libraries(rex ${PCRE_LIBRARIES})
add_executable(luacmd src/main.c ${CMAKE_CURRENT_BINARY_DIR}/luacmd.c)



set(CMAKE_MATH_LIBS m)

target_link_libraries(luacmd
    rex
    ${LUA_LIBRARY}
    ${CMAKE_DL_LIBS}
    ${CMAKE_MATH_LIBS}
#    ${PCRE_LIBRARIES}
)
set_target_properties(luacmd PROPERTIES
    ENABLE_EXPORTS true)



install(TARGETS luacmd
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib)

add_custom_target(test
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/DESIGN DESIGN
    COMMAND chmod a+x ${CMAKE_CURRENT_BINARY_DIR}/luacmd
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/runtests.sh ${CMAKE_CURRENT_BINARY_DIR}/luacmd
)
