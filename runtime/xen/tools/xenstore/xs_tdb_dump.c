/* Simple program to dump out all records of TDB */
#include <stdint.h>
#include <stdlib.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include "xs_lib.h"
#include "tdb.h"
#include "talloc.h"
#include "utils.h"

struct record_hdr {
	uint32_t num_perms;
	uint32_t datalen;
	uint32_t childlen;
	struct xs_permissions perms[0];
};

static uint32_t total_size(struct record_hdr *hdr)
{
	return sizeof(*hdr) + hdr->num_perms * sizeof(struct xs_permissions) 
		+ hdr->datalen + hdr->childlen;
}

static char perm_to_char(enum xs_perm_type perm)
{
	return perm == XS_PERM_READ ? 'r' :
		perm == XS_PERM_WRITE ? 'w' :
		perm == XS_PERM_NONE ? '-' :
		perm == (XS_PERM_READ|XS_PERM_WRITE) ? 'b' :
		'?';
}

int main(int argc, char *argv[])
{
	TDB_DATA key;
	TDB_CONTEXT *tdb;

	if (argc != 2)
		barf("Usage: xs_tdb_dump <tdbfile>");

	tdb = tdb_open(talloc_strdup(NULL, argv[1]), 0, 0, O_RDONLY, 0);
	if (!tdb)
		barf_perror("Could not open %s", argv[1]);

	key = tdb_firstkey(tdb);
	while (key.dptr) {
		TDB_DATA data;
		struct record_hdr *hdr;

		data = tdb_fetch(tdb, key);
		hdr = (void *)data.dptr;
		if (data.dsize < sizeof(*hdr))
			fprintf(stderr, "%.*s: BAD truncated\n",
				(int)key.dsize, key.dptr);
		else if (data.dsize != total_size(hdr))
			fprintf(stderr, "%.*s: BAD length %i for %i/%i/%i (%i)\n",
				(int)key.dsize, key.dptr, (int)data.dsize,
				hdr->num_perms, hdr->datalen,
				hdr->childlen, total_size(hdr));
		else {
			unsigned int i;
			char *p;

			printf("%.*s: ", (int)key.dsize, key.dptr);
			for (i = 0; i < hdr->num_perms; i++)
				printf("%s%c%i",
				       i == 0 ? "" : ",",
				       perm_to_char(hdr->perms[i].perms),
				       hdr->perms[i].id);
			p = (void *)&hdr->perms[hdr->num_perms];
			printf(" %.*s\n", hdr->datalen, p);
			p += hdr->datalen;
			for (i = 0; i < hdr->childlen; i += strlen(p+i)+1)
				printf("\t-> %s\n", p+i);
		}
		key = tdb_nextkey(tdb, key);
	}
	return 0;
}

