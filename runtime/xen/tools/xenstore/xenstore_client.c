/*
 * This file is subject to the terms and conditions of the GNU General
 * Public License.  See the file "COPYING" in the main directory of
 * this archive for more details.
 *
 * Copyright (C) 2005 by Christian Limpach
 * Copyright (C) 2005 XenSource Ltd.
 *
 */

#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <xs.h>

#include <sys/ioctl.h>

#define PATH_SEP '/'
#define MAX_PATH_LEN 256

#define MAX_PERMS 16

enum mode {
    MODE_unknown,
    MODE_chmod,
    MODE_exists,
    MODE_list,
    MODE_ls,
    MODE_read,
    MODE_rm,
    MODE_write,
};

static char *output_buf = NULL;
static int output_pos = 0;

static int output_size = 0;

static void
output(const char *fmt, ...) {
    va_list ap;
    int len;
    char buf[1];

    va_start(ap, fmt);
    len = vsnprintf(buf, 1, fmt, ap);
    if (len < 0)
	err(1, "output");
    va_end(ap);
    if (len + 1 + output_pos > output_size) {
	output_size += len + 1024;
	output_buf = realloc(output_buf, output_size);
	if (output_buf == NULL)
	    err(1, "malloc");
    }
    va_start(ap, fmt);
    if (vsnprintf(&output_buf[output_pos], len + 1, fmt, ap) != len)
	err(1, "output");
    va_end(ap);
    output_pos += len;
}

static void
usage(enum mode mode, int incl_mode, const char *progname)
{
    const char *mstr = NULL;

    switch (mode) {
    case MODE_unknown:
	errx(1, "Usage: %s <mode> [-h] [...]", progname);
    case MODE_read:
	mstr = incl_mode ? "read " : "";
	errx(1, "Usage: %s %s[-h] [-p] [-s] key [...]", progname, mstr);
    case MODE_write:
	mstr = incl_mode ? "write " : "";
	errx(1, "Usage: %s %s[-h] [-s] key value [...]", progname, mstr);
    case MODE_rm:
	mstr = incl_mode ? "rm " : "";
	errx(1, "Usage: %s %s[-h] [-s] [-t] key [...]", progname, mstr);
    case MODE_exists:
	mstr = incl_mode ? "exists " : "";
    case MODE_list:
	mstr = mstr ? : incl_mode ? "list " : "";
	errx(1, "Usage: %s %s[-h] [-s] key [...]", progname, mstr);
    case MODE_ls:
	mstr = mstr ? : incl_mode ? "ls " : "";
	errx(1, "Usage: %s %s[-h] [-s] [path]", progname, mstr);
    case MODE_chmod:
	mstr = incl_mode ? "chmod " : "";
	errx(1, "Usage: %s %s[-h] [-s] key <mode [modes...]>", progname, mstr);
    }
}


static int
do_rm(char *path, struct xs_handle *xsh, xs_transaction_t xth)
{
    if (xs_rm(xsh, xth, path)) {
        return 0;
    }
    else {
        warnx("could not remove path %s", path);
        return 1;
    }
}

#define STRING_MAX XENSTORE_ABS_PATH_MAX+1024
static int max_width = 80;
static int desired_width = 60;
static int show_whole_path = 0;

#define TAG " = \"...\""
#define TAG_LEN strlen(TAG)

#define MIN(a, b) (((a) < (b))? (a) : (b))

static void do_ls(struct xs_handle *h, char *path, int cur_depth, int show_perms)
{
    static struct expanding_buffer ebuf;
    char **e;
    char newpath[STRING_MAX], *val;
    int newpath_len;
    int i;
    unsigned int num, len;

    e = xs_directory(h, XBT_NULL, path, &num);
    if (e == NULL)
        err(1, "xs_directory (%s)", path);

    for (i = 0; i<num; i++) {
        char buf[MAX_STRLEN(unsigned int)+1];
        struct xs_permissions *perms;
        unsigned int nperms;
        int linewid;

        /* Compose fullpath */
        newpath_len = snprintf(newpath, sizeof(newpath), "%s%s%s", path, 
                path[strlen(path)-1] == '/' ? "" : "/", 
                e[i]);

        /* Print indent and path basename */
        linewid = 0;
        if (show_whole_path) {
            fputs(newpath, stdout);
        } else {
            for (; linewid<cur_depth; linewid++) {
                putchar(' ');
            }
            linewid += printf("%.*s",
                              (int) (max_width - TAG_LEN - linewid), e[i]);
        }

	/* Fetch value */
        if ( newpath_len < sizeof(newpath) ) {
            val = xs_read(h, XBT_NULL, newpath, &len);
        }
        else {
            /* Path was truncated and thus invalid */
            val = NULL;
            len = 0;
        }

        /* Print value */
        if (val == NULL) {
            printf(":\n");
        }
        else {
            if (max_width < (linewid + len + TAG_LEN)) {
                printf(" = \"%.*s\\...\"",
                       (int)(max_width - TAG_LEN - linewid),
		       sanitise_value(&ebuf, val, len));
            }
            else {
                linewid += printf(" = \"%s\"",
				  sanitise_value(&ebuf, val, len));
                if (show_perms) {
                    putchar(' ');
                    for (linewid++;
                         linewid < MIN(desired_width, max_width);
                         linewid++)
                        putchar((linewid & 1)? '.' : ' ');
                }
            }
        }
        free(val);

        if (show_perms) {
            perms = xs_get_permissions(h, XBT_NULL, newpath, &nperms);
            if (perms == NULL) {
                warn("\ncould not access permissions for %s", e[i]);
            }
            else {
                int i;
                fputs("  (", stdout);
                for (i = 0; i < nperms; i++) {
                    if (i)
                        putchar(',');
                    xs_perm_to_string(perms+i, buf, sizeof(buf));
                    fputs(buf, stdout);
                }
                putchar(')');
            }
        }

        putchar('\n');
            
        do_ls(h, newpath, cur_depth+1, show_perms); 
    }
    free(e);
}

static void
do_chmod(char *path, struct xs_permissions *perms, int nperms, int upto,
	 int recurse, struct xs_handle *xsh, xs_transaction_t xth)
{
    int ret;

    if (!path[0])
	return;

    ret = xs_set_permissions(xsh, xth, path, perms, nperms);
    if (!ret)
	err(1, "Error occurred setting permissions on '%s'", path);

    if (upto) {
	/* apply same permissions to all parent entries: */
	char *path_sep_ptr = strrchr(path, PATH_SEP);
	if (!path_sep_ptr)
	    errx(1, "Unable to locate path separator '%c' in '%s'",
		 PATH_SEP, path);
	
	*path_sep_ptr = '\0'; /* truncate path */
	
	do_chmod(path, perms, nperms, 1, 0, xsh, xth);

	*path_sep_ptr = PATH_SEP;
    }

    if (recurse) {
	char buf[MAX_PATH_LEN];

	/* apply same permissions to all child entries: */
	unsigned int xsval_n;
	char **xsval = xs_directory(xsh, xth, path, &xsval_n);

	if (xsval) {
	    int i;
	    for (i = 0; i < xsval_n; i++) {
		snprintf(buf, MAX_PATH_LEN, "%s/%s", path, xsval[i]);

		do_chmod(buf, perms, nperms, 0, 1, xsh, xth);
	    }

	    free(xsval);
	}
    }
}

static int
perform(enum mode mode, int optind, int argc, char **argv, struct xs_handle *xsh,
        xs_transaction_t xth, int prefix, int tidy, int upto, int recurse)
{
    switch (mode) {
    case MODE_ls:
	if (optind == argc)
	{
	    optind=0;
	    argc=1;
	    argv[0] = "/";
	}
	break;
    default:
	break;
    }

    while (optind < argc) {
        switch (mode) {
        case MODE_unknown:
            /* CANNOT BE REACHED */
            errx(1, "invalid mode %d", mode);
        case MODE_read: {
            static struct expanding_buffer ebuf;
            unsigned len;
            char *val = xs_read(xsh, xth, argv[optind], &len);
            if (val == NULL) {
                warnx("couldn't read path %s", argv[optind]);
                return 1;
            }
            if (prefix)
                output("%s: ", argv[optind]);
            output("%s\n", sanitise_value(&ebuf, val, len));
            free(val);
            optind++;
            break;
        }
        case MODE_write: {
            static struct expanding_buffer ebuf;
            char *val_spec = argv[optind + 1];
            unsigned len;
            expanding_buffer_ensure(&ebuf, strlen(val_spec)+1);
            unsanitise_value(ebuf.buf, &len, val_spec);
            if (!xs_write(xsh, xth, argv[optind], ebuf.buf, len)) {
                warnx("could not write path %s", argv[optind]);
                return 1;
            }
            optind += 2;
        } break;
        case MODE_rm: {
            /* Remove the specified path.  If the tidy flag is set, then also
               remove any containing directories that are both empty and have no
               value attached, and repeat, recursing all the way up to the root if
               necessary.
            */

            char *slash, *path = argv[optind];

            if (tidy) {
                /* Copy path, because we can't modify argv because we will need it
                   again if xs_transaction_end gives us EAGAIN. */
                char *p = malloc(strlen(path) + 1);
                strcpy(p, path);
                path = p;

            again:
                if (do_rm(path, xsh, xth)) {
                    return 1;
                }

                slash = strrchr(p, '/');
                if (slash) {
                    char *val;
                    unsigned len;
                    *slash = '\0';
                    val = xs_read(xsh, xth, p, &len);
                    if (val && len == 0) {
                        unsigned int num;
                        char ** list = xs_directory(xsh, xth, p, &num);

                        if (list && num == 0) {
                            goto again;
                        }
                    }
                }

                free(path);
            }
            else {
                if (do_rm(path, xsh, xth)) {
                    return 1;
                }
            }

            optind++;
            break;
        }
        case MODE_exists: {
            char *val = xs_read(xsh, xth, argv[optind], NULL);
            if (val == NULL) {
                return 1;
            }
            free(val);
            optind++;
            break;
        }
        case MODE_list: {
            unsigned int i, num;
            char **list = xs_directory(xsh, xth, argv[optind], &num);
            if (list == NULL) {
                warnx("could not list path %s", argv[optind]);
                return 1;
            }
            for (i = 0; i < num; i++) {
                if (prefix)
                    output("%s/", argv[optind]);
                output("%s\n", list[i]);
            }
            free(list);
	    optind++;
	    break;
	}
	case MODE_ls: {
	    do_ls(xsh, argv[optind], 0, prefix);
 	    optind++;
 	    break;
        }
        case MODE_chmod: {
            struct xs_permissions perms[MAX_PERMS];
            int nperms = 0;
            /* save path pointer: */
            char *path = argv[optind++];
            for (; argv[optind]; optind++, nperms++)
            {
                if (MAX_PERMS <= nperms)
                    errx(1, "Too many permissions specified.  "
			 "Maximum per invocation is %d.", MAX_PERMS);

                perms[nperms].id = atoi(argv[optind]+1);

                switch (argv[optind][0])
                {
                case 'n':
                    perms[nperms].perms = XS_PERM_NONE;
                    break;
                case 'r':
                    perms[nperms].perms = XS_PERM_READ;
                    break;
                case 'w':
                    perms[nperms].perms = XS_PERM_WRITE;
                    break;
                case 'b':
                    perms[nperms].perms = XS_PERM_READ | XS_PERM_WRITE;
                    break;
                default:
                    errx(1, "Invalid permission specification: '%c'",
			 argv[optind][0]);
                }
            }

            do_chmod(path, perms, nperms, upto, recurse, xsh, xth);
            break;
        }
        }
    }

    return 0;
}

static enum mode lookup_mode(const char *m)
{
    if (strcmp(m, "read") == 0)
	return MODE_read;
    else if (strcmp(m, "chmod") == 0)
	return MODE_chmod;
    else if (strcmp(m, "exists") == 0)
	return MODE_exists;
    else if (strcmp(m, "list") == 0)
	return MODE_list;
    else if (strcmp(m, "ls") == 0)
	return MODE_ls;
    else if (strcmp(m, "rm") == 0)
	return MODE_rm;
    else if (strcmp(m, "write") == 0)
	return MODE_write;
    else if (strcmp(m, "read") == 0)
	return MODE_read;

    errx(1, "unknown mode %s\n", m);
    return 0;
}

int
main(int argc, char **argv)
{
    struct xs_handle *xsh;
    xs_transaction_t xth = XBT_NULL;
    int ret = 0, socket = 0;
    int prefix = 0;
    int tidy = 0;
    int upto = 0;
    int recurse = 0;
    int transaction;
    struct winsize ws;
    enum mode mode;

    const char *_command = strrchr(argv[0], '/');
    const char *command = _command ? &_command[1] : argv[0];
    int switch_argv = -1; /* which element of argv did we switch on */

    if (strncmp(command, "xenstore-", strlen("xenstore-")) == 0)
    {
	switch_argv = 0;
	command = command + strlen("xenstore-");
    }
    else if (argc < 2)
	usage(MODE_unknown, 0, argv[0]);
    else
    {
	command = argv[1];
	switch_argv = 1;
    }

    mode = lookup_mode(command);

    while (1) {
	int c, index = 0;
	static struct option long_options[] = {
	    {"help",    0, 0, 'h'},
	    {"socket",  0, 0, 's'},
	    {"prefix",  0, 0, 'p'}, /* MODE_read || MODE_list */
	    {"tidy",    0, 0, 't'}, /* MODE_rm */
	    {"upto",    0, 0, 'u'}, /* MODE_chmod */
	    {"recurse", 0, 0, 'r'}, /* MODE_chmod */
	    {0, 0, 0, 0}
	};

	c = getopt_long(argc - switch_argv, argv + switch_argv, "fhsptur",
			long_options, &index);
	if (c == -1)
	    break;

	switch (c) {
	case 'h':
	    usage(mode, switch_argv, argv[0]);
	    /* NOTREACHED */
        case 'f':
	    if ( mode == MODE_read || mode == MODE_list || mode == MODE_ls ) {
		max_width = INT_MAX/2;
		desired_width = 0;
		show_whole_path = 1;
	    } else {
		usage(mode, switch_argv, argv[0]);
	    }
            break;
        case 's':
            socket = 1;
            break;
	case 'p':
	    if ( mode == MODE_read || mode == MODE_list || mode == MODE_ls )
		prefix = 1;
	    else
		usage(mode, switch_argv, argv[0]);
	    break;
	case 't':
	    if ( mode == MODE_rm )
		tidy = 1;
	    else
		usage(mode, switch_argv, argv[0]);
	    break;
	case 'u':
	    if ( mode == MODE_chmod )
		upto = 1;
	    else
		usage(mode, switch_argv, argv[0]);
	    break;
	case 'r':
	    if ( mode == MODE_chmod )
		recurse = 1;
	    else
		usage(mode, switch_argv, argv[0]);
	    break;
	}
    }

    switch (mode) {
    case MODE_ls:
	break;
    case MODE_write:
	if ((argc - switch_argv - optind) % 2 == 1) {
	    usage(mode, switch_argv, argv[0]);
	    /* NOTREACHED */
	}
	/* DROP-THRU */
    default:
	if (optind == argc - switch_argv) {
	    usage(mode, switch_argv, argv[0]);
	    /* NOTREACHED */
	}
    }

    switch (mode) {
    case MODE_read:
	transaction = (argc - switch_argv - optind) > 1;
	break;
    case MODE_write:
	transaction = (argc - switch_argv - optind) > 2;
	break;
    case MODE_ls:
	transaction = 0;
	break;
    default:
	transaction = 1;
	break;
    }

    if ( mode == MODE_ls )
    {
	memset(&ws, 0, sizeof(ws));
	ret = ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws);
	if (!ret)
	    max_width = ws.ws_col - 2;
    }

    xsh = socket ? xs_daemon_open() : xs_domain_open();
    if (xsh == NULL)
	err(1, socket ? "xs_daemon_open" : "xs_domain_open");

again:
    if (transaction) {
	xth = xs_transaction_start(xsh);
	if (xth == XBT_NULL)
	    errx(1, "couldn't start transaction");
    }

    ret = perform(mode, optind, argc - switch_argv, argv + switch_argv, xsh, xth, prefix, tidy, upto, recurse);

    if (transaction && !xs_transaction_end(xsh, xth, ret)) {
	if (ret == 0 && errno == EAGAIN) {
	    output_pos = 0;
	    goto again;
	}
	errx(1, "couldn't end transaction");
    }

    if (output_pos)
	printf("%s", output_buf);

    return ret;
}
