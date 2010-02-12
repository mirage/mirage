#ifndef _REGEX_H
#define _REGEX_H

#include <sys/cdefs.h>
#include <sys/types.h>

__BEGIN_DECLS

typedef ptrdiff_t regoff_t;

typedef struct {
  regoff_t rm_so;
  regoff_t rm_eo;
} regmatch_t;

#define REG_EXTENDED 1
#define REG_ICASE 2
#define REG_NOSUB 4
#define REG_NEWLINE 8

#define REG_NOTBOL 1
#define REG_NOTEOL 2

#define REG_NOMATCH -1

#define RE_DUP_MAX 8192

struct __regex_t;

typedef int (*matcher)(void*,const char*,int ofs,struct __regex_t* t,int plus,int eflags);

typedef struct __regex_t {
  struct regex {
    matcher m;
    void* next;
    int pieces;
    int num;
    struct branch* b;
  } r;
  int brackets,cflags;
  regmatch_t* l;
} regex_t;
#define re_nsub r.pieces

int regcomp(regex_t* preg, const char* regex, int cflags) __THROW;
int regexec(const regex_t* preg, const char* string, size_t nmatch, regmatch_t pmatch[], int eflags) __THROW;
size_t regerror(int errcode, const regex_t* preg, char* errbuf, size_t errbuf_size) __THROW;
void regfree(regex_t* preg) __THROW;

enum __regex_errors {
  REG_NOERROR,
  REG_BADRPT, /* Invalid use of repetition operators such as using `*' as the first character. */
  REG_BADBR, /* Invalid use of back reference operator. */
  REG_EBRACE, /* Un-matched brace interval operators. */
  REG_EBRACK, /* Un-matched bracket list operators. */
  REG_ERANGE, /* Invalid use of the range operator, eg. the ending point of the
		 range occurs  prior  to  the  starting point. */
  REG_ECTYPE, /* Unknown character class name. */
  REG_ECOLLATE, /* Invalid collating element. */
  REG_EPAREN, /* Un-matched parenthesis group operators. */
  REG_ESUBREG, /* Invalid back reference to a subexpression. */
  REG_EEND, /* Non specific error.  This is not defined by POSIX.2. */
  REG_EESCAPE, /* Trailing backslash. */
  REG_BADPAT, /* Invalid use of pattern operators such as group or list. */
  REG_ESIZE, /* Compiled  regular  expression  requires  a  pattern  buffer
		larger than 64Kb.  This is not defined by POSIX.2. */
  REG_ESPACE /* regcomp ran out of space */
};

char* re_comp(char* regex);
int re_exec(char* string);

__END_DECLS

#endif
