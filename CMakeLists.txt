cmake_minimum_required(VERSION 2.8)

project(luacmd)

set (luacmd_VERSION_MAJOR 0)
set (luacmd_VERSION_MINOR 1)
set (luacmd_VERSION_PATCH 4)

if (EXCLUDE_GIT_VERSION)
else (EXCLUDE_GIT_VERSION)
# Get the current working branch
execute_process(
  COMMAND git rev-parse --abbrev-ref HEAD
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  OUTPUT_VARIABLE GIT_BRANCH
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
# Get the latest abbreviated commit hash of the working branch
execute_process(
  COMMAND git log -1 --format=%h
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  OUTPUT_VARIABLE GIT_COMMIT_HASH
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
endif(EXCLUDE_GIT_VERSION)

configure_file (
    ${PROJECT_SOURCE_DIR}/src/config.lua.in
    ${PROJECT_BINARY_DIR}/config.lua
)

set (CMAKE_CXX_FLAGS "/MT")

include(ExternalProject)

FUNCTION(PREPEND var prefix)
   SET(listVar "")
   FOREACH(f ${ARGN})
      LIST(APPEND listVar "${prefix}/${f}")
   ENDFOREACH(f)
   SET(${var} "${listVar}" PARENT_SCOPE)
ENDFUNCTION(PREPEND)

set (CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(ljpre ${CMAKE_CURRENT_BINARY_DIR}/luajit-2.0.3)
set(ljsrc ${ljpre}/src/project_luajit/src)
# If CROSSCC is set in environment we are cross compiling (prob 32 on 64)
if("$ENV{CROSSCC}" STREQUAL "")
    set(cross_flag "")
else("$ENV{CROSSCC}" STREQUAL "")
    set(cross_flag "CC=$ENV{CROSSCC}")
    message("!!!!!!Cross compiling!!!!!!!! ${cross_flag}")
endif("$ENV{CROSSCC}" STREQUAL "")

if(UNIX)
    ExternalProject_Add(project_luajit
      URL ${CMAKE_CURRENT_SOURCE_DIR}/external/LuaJIT-2.0.3.tar.gz
      PREFIX ${ljpre}
      CONFIGURE_COMMAND ""
      BUILD_IN_SOURCE 1
      BUILD_COMMAND make -j8 ${cross_flag}
      INSTALL_COMMAND ""
      COMMAND ${CMAKE_COMMAND} -E copy ${ljsrc}/luajit ${ljpre}
      COMMAND ${CMAKE_COMMAND} -E copy ${ljsrc}/libluajit.a ${ljpre}
      COMMAND ${CMAKE_COMMAND} -E copy_directory ${ljsrc}/jit ${ljpre}/jit
    )
    set (ljname libluajit.a)
else(UNIX)
    ExternalProject_Add(project_luajit
      URL ${CMAKE_CURRENT_SOURCE_DIR}/external/LuaJIT-2.0.3.tar.gz
      PREFIX ${ljpre}
      CONFIGURE_COMMAND ""
      BINARY_DIR ${ljsrc}
      BUILD_COMMAND ${ljsrc}/msvcbuild.bat
      INSTALL_COMMAND ""
      COMMAND ${CMAKE_COMMAND} -E copy ${ljsrc}/luajit.exe ${ljpre}
      COMMAND ${CMAKE_COMMAND} -E copy ${ljsrc}/lua51.dll ${ljpre}
      COMMAND ${CMAKE_COMMAND} -E copy ${ljsrc}/lua51.lib ${ljpre}
      COMMAND ${CMAKE_COMMAND} -E copy_directory ${ljsrc}/jit ${ljpre}/lua/jit
    )
    set (ljname lua51.lib)
    set (ljdllname lua51.dll)
endif(UNIX)
add_library(luajit STATIC IMPORTED)
set_property(TARGET luajit PROPERTY IMPORTED_LOCATION ${ljpre}/${ljname})
add_dependencies(luajit project_luajit)
ExternalProject_Get_Property(project_luajit source_dir)
set(LUA_INCLUDE_DIR ${source_dir}/src)
set(LUA_BINARY ${ljpre}/luajit)

set(LUA_FILES src/inspect.lua src/boot.lua src/main.lua)
prepend(LUA_FILES_DIR ${CMAKE_CURRENT_SOURCE_DIR} ${LUA_FILES})
set(LUA_FILES_DIR ${PROJECT_BINARY_DIR}/config.lua ${LUA_FILES_DIR})

add_custom_command(
    DEPENDS project_luajit ${LUA_FILES_DIR}
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/luacmd.c
    WORKING_DIRECTORY ${ljpre}
    COMMAND ${LUA_BINARY} ${CMAKE_CURRENT_SOURCE_DIR}/tools/combiner.lua ${LUA_FILES_DIR} > ${CMAKE_CURRENT_BINARY_DIR}/luacmd.lua
    COMMAND ${LUA_BINARY} -b -n luacmd ${CMAKE_CURRENT_BINARY_DIR}/luacmd.lua ${CMAKE_CURRENT_BINARY_DIR}/luacmd.c
)

ExternalProject_Add(project_pcre
  URL ${CMAKE_CURRENT_SOURCE_DIR}/external/pcre-8.36.tar.gz
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/pcre-8.36
  CMAKE_ARGS
  BUILD_COMMAND "${CMAKE_COMMAND}" --build . --target pcre
  INSTALL_COMMAND ""
)
ExternalProject_Get_Property(project_pcre binary_dir)
add_library(pcre STATIC IMPORTED)
if(UNIX)
	set (PCRE_LIB ${binary_dir}/libpcre.a)
else(UNIX)
	set (PCRE_LIB ${binary_dir}/pcred.lib)
endif(UNIX)
set_property(TARGET pcre PROPERTY IMPORTED_LOCATION ${PCRE_LIB})
add_dependencies(pcre project_pcre)
include_directories(${binary_dir})

include_directories(${LUA_INCLUDE_DIR})
set(LREX_SRC
    external/lrexlib-2.7.2/src/common.c
    external/lrexlib-2.7.2/src/pcre/lpcre.c
    external/lrexlib-2.7.2/src/pcre/lpcre_f.c
)
add_definitions(-DVERSION=\"2.7.2\")
add_definitions(-DREX_OPENLIB=luaopen_librex)
add_definitions(-DPCRE_STATIC)
add_library(rex STATIC ${LREX_SRC})
add_dependencies(rex project_luajit)
target_link_libraries(rex pcre)

add_executable(luacmd src/main.c ${CMAKE_CURRENT_BINARY_DIR}/luacmd.c)
if(APPLE)
	# 64-bit Mac OS X requires special flags to free up low 32-bit addresses for GC
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pagezero_size 10000 -image_base 100000000")
endif(APPLE)

if(UNIX)
	set(CMAKE_MATH_LIBS m)
endif(UNIX)

target_link_libraries(
	luacmd
    pcre
    rex
    luajit
    ${CMAKE_DL_LIBS}
    ${CMAKE_MATH_LIBS}
)
set_target_properties(luacmd PROPERTIES
    ENABLE_EXPORTS true)

include (InstallRequiredSystemLibraries)

install(TARGETS luacmd
    RUNTIME DESTINATION bin
    COMPONENT Executable)
if(UNIX)
else(UNIX)
install(FILES ${ljpre}/${ljdllname}
	DESTINATION bin
	COMPONENT Libraries)
INSTALL(FILES ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS}
	DESTINATION bin
	COMPONENT Libraries)
endif(UNIX)
add_custom_target(unittest
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/DESIGN DESIGN
    COMMAND chmod a+x ${CMAKE_CURRENT_BINARY_DIR}/luacmd
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/runtests.sh ${CMAKE_CURRENT_BINARY_DIR}/luacmd
)


foreach(flag_var
        CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
        CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
   if(${flag_var} MATCHES "/MD")
      string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
   endif(${flag_var} MATCHES "/MD")
endforeach(flag_var)



# All platforms get ZIP file
set (CPACK_GENERATOR ZIP)
# Windows gets custom installer
if(WIN32)
    set (CPACK_GENERATOR ${CPACK_GENERATOR} NSIS)
endif(WIN32)

set (CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE.rtf")
set (CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
set (CPACK_PACKAGE_VERSION_MAJOR "${luacmd_VERSION_MAJOR}")
set (CPACK_PACKAGE_VERSION_MINOR "${luacmd_VERSION_MINOR}")
set (CPACK_PACKAGE_VERSION_PATCH "${luacmd_VERSION_PATCH}")
set (CPACK_PACKAGE_VENDOR "Nathan Whitehead")
set (CPACK_PACKAGE_EXECUTABLES "luacmd" "LuaCommand")
set (CPACK_NSIS_MODIFY_PATH ON)

include (CPack)

