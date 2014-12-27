OUTPUT = out/luacmd
CSOURCE = src/main.c
REGEXOBJS = regex/common.o regex/pcre/lpcre.o regex/pcre/lpcre_f.o
LUAOBJLIB = out/libluafiles.a
LUAOBJS = src/inspect.o src/boot.o
OBJS = ${CSOURCE:.c=.o}
CC = gcc
CINCLUDE = /usr/local/include/luajit-2.0
CFLAGS = -O2 ${foreach d, ${CINCLUDE}, -I$d} -fpic -DREGEXVERSION=\"2.7.1\"
LFLAGS = -lluajit-5.1 -lpcre -ldl -Wl,-E
REGEXLIB = out/librex_pcre.so
LUA = luajit

all: ${OUTPUT}

${OUTPUT}: ${OBJS} ${LUAOBJS} ${REGEXLIB}
	mkdir -p out/
	${CC} -o $@ ${OBJS} ${LUAOBJS} ${REGEXLIB} ${LFLAGS}

%.o : %.c
	${CC} -c -o $@ $< ${CFLAGS}

%.o : %.lua
	${LUA} -b $< $@

${LUAOBJLIB} : ${LUAOBJS}
	${AR} rcus $@ ${LUAOBJS}

clean:
	rm -f ${OUTPUT} ${OBJS} ${REGEXOBJS} ${REGEXLIB} ${LUAOBJS} ${LUAOBJLIB}
	rm -fr out/

test: ${OUTPUT}
	./runtests.sh ${OUTPUT}

${REGEXLIB}: ${REGEXOBJS}
	mkdir -p out/
	#ar rcs ${REGEXLIB} ${REGEXOBJS}
	gcc -shared $< -o $@ ${LFLAGS}

.PHONY: all clean test
