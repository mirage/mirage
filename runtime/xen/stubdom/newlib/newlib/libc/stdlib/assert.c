/*
FUNCTION
<<assert>>---macro for debugging diagnostics

INDEX
	assert

ANSI_SYNOPSIS
	#include <assert.h>
	void assert(int <[expression]>);

DESCRIPTION
	Use this macro to embed debuggging diagnostic statements in
	your programs.  The argument <[expression]> should be an
	expression which evaluates to true (nonzero) when your program
	is working as you intended.

	When <[expression]> evaluates to false (zero), <<assert>>
	calls <<abort>>, after first printing a message showing what
	failed and where:

. Assertion failed: <[expression]>, file <[filename]>, line <[lineno]>, function: <[func]>

	If the name of the current function is not known (for example,
	when using a C89 compiler that does not understand __func__),
	the function location is omitted.

	The macro is defined to permit you to turn off all uses of
	<<assert>> at compile time by defining <<NDEBUG>> as a
	preprocessor variable.   If you do this, the <<assert>> macro
	expands to

. (void(0))

RETURNS
	<<assert>> does not return a value.

PORTABILITY
	The <<assert>> macro is required by ANSI, as is the behavior
	when <<NDEBUG>> is defined.

Supporting OS subroutines required (only if enabled): <<close>>, <<fstat>>,
<<getpid>>, <<isatty>>, <<kill>>, <<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

/* func can be NULL, in which case no function information is given.  */
void
_DEFUN (__assert_func, (file, line, func, failedexpr),
	const char *file _AND
	int line _AND
	const char *func _AND
	const char *failedexpr)
{
  fiprintf(stderr,
	   "assertion \"%s\" failed: file \"%s\", line %d%s%s\n",
	   failedexpr, file, line,
	   func ? ", function: " : "", func ? func : "");
  abort();
  /* NOTREACHED */
}

void
_DEFUN (__assert, (file, line, failedexpr),
	const char *file _AND
	int line _AND
	const char *failedexpr)
{
   __assert_func (file, line, NULL, failedexpr);
  /* NOTREACHED */
}
