SUBDIRS="dirent inet stdio string stdlib time"

TESTPROGRAMS="adjtime argv atexit bsearch byteswap calloc confstr empty flush fputc ffs fnmatch ftw fwrite getaddrinfo getenv getdelim getgrnam gethostbyaddr gethostbyname gethostbyname_r getmntent getopt getpwnam getservbyname getservbyport getusershell glob grent hasmntopt hello iconv if_nameindex ltostr malloc-debugger md5_testharness memccpy memchr memcmp memrchr memusage mktime mmap_test pipe printf printftest protoent prototypes putenv pwent rand48 readdir regex select sendfile servent siglist speed spent sprintf sscanf stdarg strcasecmp strcmp strncat strncpy strptime strrchr strstr strtol sysenter ungetc waitpid"

STDIN="read1"
PASS="getpass" 

CWD=`pwd`

for d in $SUBDIRS; do
 echo Entering directory $d
 cd $d && ./runtests.sh
 cd "$CWD" || exit 1
done


for p in $TESTPROGRAMS; do
echo "---";echo testing $p;echo "---"
 ./$p ||  ( echo TESTCASE $p exited non-zero 1>&2 ; sleep 5 )
done 

./asprintf foobar  ||  ( echo TESTCASE asprintf exited non-zero 1>&2 ; sleep 5 )
./cycles strncpy ||  ( echo TESTCASE cycles exited non-zero 1>&2 ; sleep 5 )

for p in $STDIN;do
echo "---";echo testing $p;echo "---"
echo foobar | ./$p || ( echo TESTCASE $p exited non-zero 1>&2 ; sleep 5)
done

for p in $PASS;do
 echo "---";echo testing $p;echo "---"
 echo if you are not prompted for input it is broken
 sleep 2
 echo foobar | ./$p || ( echo TESTCASE $p exited non-zero 1>&2 ; sleep 5)
done


