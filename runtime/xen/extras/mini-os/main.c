/*
 * POSIX-compatible main layer
 *
 * Samuel Thibault <Samuel.Thibault@eu.citrix.net>, October 2007
 */

#include <os.h>
#include <sched.h>
#include <console.h>
#include <netfront.h>
#include <time.h>
#include <stdlib.h>
#include <unistd.h>
#include <xenbus.h>
#include <events.h>

extern int main(int argc, char *argv[], char *envp[]);
extern void __libc_init_array(void);
extern void __libc_fini_array(void);
extern unsigned long __CTOR_LIST__[];
extern unsigned long __DTOR_LIST__[];

void _init(void)
{
}

void _fini(void)
{
}

extern char __app_bss_start, __app_bss_end;
static void call_main(void *p)
{
    char *c, quote;
    int argc;
    char **argv;
    char *envp[] = { NULL };
    int i;

    /* Let other parts initialize (including console output) before maybe
     * crashing. */
    sleep(1);

    sparse((unsigned long) &__app_bss_start, &__app_bss_end - &__app_bss_start);
#if defined(HAVE_LWIP)
    // start_networking();
#endif

    argc = 1;

#define PARSE_ARGS(ARGS,START,QUOTE,END) \
    c = ARGS; \
    quote = 0; \
    while (*c) { \
	if (*c != ' ') { \
	    START; \
	    while (*c) { \
		if (quote) { \
		    if (*c == quote) { \
			quote = 0; \
			QUOTE; \
			continue; \
		    } \
		} else if (*c == ' ') \
		    break; \
		if (*c == '"' || *c == '\'') { \
		    quote = *c; \
		    QUOTE; \
		    continue; \
		} \
		c++; \
	    } \
	} else { \
            END; \
	    while (*c == ' ') \
		c++; \
	} \
    } \
    if (quote) {\
	printk("Warning: unterminated quotation %c\n", quote); \
	quote = 0; \
    }
#define PARSE_ARGS_COUNT(ARGS) PARSE_ARGS(ARGS, argc++, c++, )
#define PARSE_ARGS_STORE(ARGS) PARSE_ARGS(ARGS, argv[argc++] = c, memmove(c, c + 1, strlen(c + 1) + 1), *c++ = 0)

    PARSE_ARGS_COUNT((char*)start_info.cmd_line);

    argv = alloca((argc + 1) * sizeof(char *));
    argv[0] = "main";
    argc = 1;

    PARSE_ARGS_STORE((char*)start_info.cmd_line)

    argv[argc] = NULL;

    for (i = 0; i < argc; i++)
	printf("\"%s\" ", argv[i]);
    printf("\n");

    __libc_init_array();
    environ = envp;
    for (i = 1; i <= __CTOR_LIST__[0]; i++)
        ((void((*)(void)))__CTOR_LIST__[i]) ();
    tzset();

    exit(main(argc, argv, envp));
}

void _exit(int ret)
{
    int i;

    for (i = 1; i <= __DTOR_LIST__[0]; i++)
        ((void((*)(void)))__DTOR_LIST__[i]) ();
    close_all_files();
    __libc_fini_array();
    printk("main returned %d\n", ret);
#ifdef HAVE_LWIP
    stop_networking();
#endif
    stop_kernel();
    if (!ret) {
	/* No problem, just shutdown.  */
        struct sched_shutdown sched_shutdown = { .reason = SHUTDOWN_poweroff };
        HYPERVISOR_sched_op(SCHEDOP_shutdown, &sched_shutdown);
    }
    do_exit();
}

int app_main(start_info_t *si)
{
    printk("Dummy main: start_info=%p\n", si);
    main_thread = create_thread("main", call_main, si);
    return 0;
}
