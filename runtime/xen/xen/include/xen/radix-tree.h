/*
 * Copyright (C) 2001 Momchil Velikov
 * Portions Copyright (C) 2001 Christoph Hellwig
 * Adapted for Xen by Dan Magenheimer, Oracle Corp.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2, or (at
 * your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */
#ifndef _XEN_RADIX_TREE_H
#define _XEN_RADIX_TREE_H

/* root tags are stored in gfp_mask, shifted by __GFP_BITS_SHIFT */
struct radix_tree_root {
    unsigned int height;
    struct radix_tree_node *rnode;
};

#define RADIX_TREE_MAP_SHIFT 6

#define RADIX_TREE_MAP_SIZE (1UL << RADIX_TREE_MAP_SHIFT)
#define RADIX_TREE_MAP_MASK (RADIX_TREE_MAP_SIZE-1)

#define RADIX_TREE_TAG_LONGS \
 ((RADIX_TREE_MAP_SIZE + BITS_PER_LONG - 1) / BITS_PER_LONG)

struct radix_tree_node {
    unsigned int count;
    void  *slots[RADIX_TREE_MAP_SIZE];
};

struct radix_tree_path {
    struct radix_tree_node *node;
    int offset;
};

#define RADIX_TREE_INDEX_BITS  (8 /* CHAR_BIT */ * sizeof(unsigned long))
#define RADIX_TREE_MAX_PATH (RADIX_TREE_INDEX_BITS/RADIX_TREE_MAP_SHIFT + 2)


#define RADIX_TREE_INIT(mask) {     \
 .height = 0,       \
 .rnode = NULL,       \
}

#define RADIX_TREE(name, mask) \
 struct radix_tree_root name = RADIX_TREE_INIT(mask)

#define INIT_RADIX_TREE(root, mask)     \
do {         \
 (root)->height = 0;      \
 (root)->rnode = NULL;      \
} while (0)

int radix_tree_insert(struct radix_tree_root *root, unsigned long index,
                      void *item, struct radix_tree_node *(*node_alloc)(void *), void *arg);
void *radix_tree_lookup(struct radix_tree_root *, unsigned long);
void **radix_tree_lookup_slot(struct radix_tree_root *, unsigned long);
void radix_tree_destroy(struct radix_tree_root *root,
                        void (*slot_free)(void *), void (*node_free)(struct radix_tree_node *));
void *radix_tree_delete(struct radix_tree_root *root, unsigned long index,
                        void(*node_free)(struct radix_tree_node *));
unsigned int
radix_tree_gang_lookup(struct radix_tree_root *root, void **results,
                       unsigned long first_index, unsigned int max_items);
void radix_tree_init(void);

#endif /* _XEN_RADIX_TREE_H */
