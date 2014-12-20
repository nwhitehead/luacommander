OUTPUT = out/luacmd
CSOURCE = src/main.c
REGEXOBJS = regex/common.o regex/pcre/lpcre.o regex/pcre/lpcre_f.o
LUAOBJLIB = out/libluafiles.a
LUAOBJS = src/inspect.o test/testmodule.init.o test/testmodule.tm.o
OBJS = ${CSOURCE:.c=.o}
CC = gcc
CINCLUDE = /usr/local/include/luajit-2.0
CFLAGS = -O2 ${foreach d, ${CINCLUDE}, -I$d} -fpic -DREGEXVERSION=\"2.7.1\"
LFLAGS = -lluajit-5.1 -lpcre -ldl -Wl,-E
REGEXLIB = out/pcre.so
LUA = luajit

all: ${OUTPUT}

${OUTPUT}: ${OBJS} ${LUAOBJS} ${REGEXLIB}
	mkdir -p out/
	${CC} -o $@ ${OBJS} ${LUAOBJS} ${REGEXLIB} ${LFLAGS}

test/testmodule.init.o: test/testmodule/init.lua
	luajit -b -n testmodule $< $@
test/testmodule.tm.o: test/testmodule/tm.lua
	luajit -b -n testmodule.tm $< $@

%.o : %.c
	${CC} -c -o $@ $< ${CFLAGS}

%.o : %.lua
	${LUA} -b $< $@

${LUAOBJLIB} : ${LUAOBJS}
	${AR} rcus $@ ${LUAOBJS}

clean:
	rm -f ${OUTPUT} ${OBJS} ${REGEXOBJS} ${REGEXLIB} ${LUAOBJS} ${LUAOBJLIB}
	rmdir out

test: ${OUTPUT}
	./${OUTPUT} -e "print('hi')"

${REGEXLIB}: ${REGEXOBJS}
	mkdir -p out/
	${CC} -shared ${REGEXOBJS} -o ${REGEXLIB}

.PHONY: all clean test
