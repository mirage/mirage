/*
 * Version of environ for no OS.
 */

char *__env[1] = { 0 }; 
char **environ = __env; 
