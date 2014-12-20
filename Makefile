OUTPUT = out/luacmd
CSOURCE = src/main.c
REGEXOBJS = regex/common.o regex/pcre/lpcre.o regex/pcre/lpcre_f.o
LUAOBJS = src/inspect.o
OBJS = ${CSOURCE:.c=.o} ${REGEXOBJS} ${LUAOBJS}
CC = gcc
CINCLUDE = /usr/local/include/luajit-2.0
CFLAGS = -O2 ${foreach d, ${CINCLUDE}, -I$d} -fpic -DREGEXVERSION=\"2.7.1\"
LFLAGS = -Wl,-E -lluajit-5.1 -lpcre -ldl
REGEXLIB = out/pcre.so
LUA = luajit

all: ${OUTPUT}

${OUTPUT}: ${OBJS} ${REGEXLIB}
	mkdir -p out/
	${CC} -o $@ ${OBJS} ${REGEXLIB} ${LFLAGS}

%.o : %.c
	${CC} -c -o $@ $< ${CFLAGS}

%.o : %.lua
	${LUA} -b $< $@

clean:
	rm -f ${OUTPUT} ${OBJS} ${REGEXOBJS} ${REGEXLIB}
	rmdir out

test: ${OUTPUT}
	./${OUTPUT} -e "print('hi')"

${REGEXLIB}: ${REGEXOBJS}
	mkdir -p out/
	${CC} -shared ${REGEXOBJS} -o ${REGEXLIB}

.PHONY: all clean test
