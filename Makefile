OUTPUT = luacmd
CSOURCE = src/main.c
OBJS = ${CSOURCE:.c=.o}
CC = clang
CINCLUDE = /usr/local/include/luajit-2.0
CFLAGS = -O2 ${foreach d, ${CINCLUDE}, -I$d}
LFLAGS = -lluajit-5.1
REGEXLIB = modules/rex_pcre.so
all: ${OUTPUT}

${OUTPUT}: ${OBJS} ${REGEXLIB}
	${CC} -o $@ ${OBJS} ${REGEXLIB} ${LFLAGS}

%.o : %.c
	${CC} -c -o $@ $< ${CFLAGS}

clean:
	rm -f ${OUTPUT} ${OBJS}

test: ${OUTPUT}
	./${OUTPUT} -e "print('hi')"

.PHONY: all clean test
