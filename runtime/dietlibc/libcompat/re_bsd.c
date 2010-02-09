/* wrapper to simulate the braindead 4.3BSD regex interface 
 * by Andreas Krennmair <a.krennmair@aon.at> 
 */
#include <regex.h>
#include <sys/types.h>

#include "dietwarning.h"

static char err_compile[] = "unable to compile regular expression.";
static int re_buf_used;
static regex_t re_buf;

char * re_comp(char * regex) {
  int rc;
  if (regex) {
    if (re_buf_used)
      regfree(&re_buf);
    rc = regcomp(&re_buf,regex,0);
    if (rc)
      return err_compile;
    re_buf_used = 1;
  }
  return NULL;
}

int re_exec(char * string) {
  if (string) {
    return regexec(&re_buf,string,0,NULL,0)?0:1;
  }
  return 0;
}

link_warning("re_comp","warning: use regcomp instead of re_comp!")
link_warning("re_exec","warning: use regexec instead of re_exec!")
