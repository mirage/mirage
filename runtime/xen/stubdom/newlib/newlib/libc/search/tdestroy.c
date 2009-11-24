/*	$NetBSD: tdelete.c,v 1.2 1999/09/16 11:45:37 lukem Exp $	*/

/*
 * Tree search generalized from Knuth (6.2.2) Algorithm T just like
 * the AT&T man page says.
 *
 * The node_t structure is for internal use only, lint doesn't grok it.
 *
 * Written by reading the System V Interface Definition, not the code.
 *
 * Totally public domain.
 */

#include <sys/cdefs.h>
#if 0
#if defined(LIBC_SCCS) && !defined(lint)
__RCSID("$NetBSD: tdelete.c,v 1.2 1999/09/16 11:45:37 lukem Exp $");
#endif /* LIBC_SCCS and not lint */
#endif

#include <assert.h>
#define _SEARCH_PRIVATE
#include <search.h>
#include <stdlib.h>


/* Walk the nodes of a tree */
static void
trecurse(root, free_action)
	node_t *root;	/* Root of the tree to be walked */
	void (*free_action)(void *);
{
  if (root->llink != NULL)
    trecurse(root->llink, free_action);
  if (root->rlink != NULL)
    trecurse(root->rlink, free_action);

  (*free_action) ((void *) root->key);
  free(root);
}

void
_DEFUN(tdestroy, (vrootp, freefct),
       void *vrootp _AND
       void (*freefct)(void *))
{
  node_t *root = (node_t *) vrootp;

  if (root != NULL)
    trecurse(root, freefct);
}
