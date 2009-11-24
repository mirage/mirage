define wec-test
set height 0
set remotedebug 0
echo Running array test...
load array-w89k.x
run
echo Running double test...
load double-w89k.x
run
echo Running float test...
load float-w89k.x
run
echo Running func test...
load func-w89k.x
run
echo Running io test...
load io-w89k.x
run
echo Running math test...
load math-w89k.x
run
echo Running memory test...
load memory-w89k.x
run
echo Running div test...
load div-w89k.x
run
echo Running struct test...
load struct-w89k.x
run
echo Running printf test...
load printf-w89k.x
run
echo Running varargs test...
load varargs-w89k.x
run
echo Running varargs2 test...
load varargs2-w89k.x
run
end

define oki-test
set height 0
set remotedebug 0
echo Running array test...
load array-op50n.x
run
echo Running double test...
load double-op50n.x
run
echo Running float test...
load float-op50n.x
run
echo Running func test...
load func-op50n.x
run
echo Running io test...
load io-op50n.x
run
echo Running math test...
load math-op50n.x
run
echo Running memory test...
load memory-op50n.x
run
echo Running div test...
load div-op50n.x
run
echo Running struct test...
load struct-op50n.x
run
echo Running printf test...
load printf-op50n.x
run
echo Running varargs test...
load varargs-op50n.x
run
echo Running varargs2 test...
load varargs2-op50n.x
run
end

