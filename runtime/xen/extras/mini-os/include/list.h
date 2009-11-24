#ifndef _LINUX_LIST_H
#define _LINUX_LIST_H

/*
 * Simple doubly linked list implementation.
 *
 * Some of the internal functions ("__xxx") are useful when
 * manipulating whole lists rather than single entries, as
 * sometimes we already know the next/prev entries and we can
 * generate better code by using them directly rather than
 * using the generic single-entry routines.
 */

struct minios_list_head {
	struct minios_list_head *next, *prev;
};

#define MINIOS_LIST_HEAD_INIT(name) { &(name), &(name) }

#define MINIOS_LIST_HEAD(name) \
	struct minios_list_head name = MINIOS_LIST_HEAD_INIT(name)

#define MINIOS_INIT_LIST_HEAD(ptr) do { \
	(ptr)->next = (ptr); (ptr)->prev = (ptr); \
} while (0)

#define minios_list_top(head, type, member)					  \
({ 									  \
	struct minios_list_head *_head = (head);				  \
	minios_list_empty(_head) ? NULL : minios_list_entry(_head->next, type, member); \
})

/*
 * Insert a new entry between two known consecutive entries. 
 *
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 */
static __inline__ void __minios_list_add(struct minios_list_head * new,
	struct minios_list_head * prev,
	struct minios_list_head * next)
{
	next->prev = new;
	new->next = next;
	new->prev = prev;
	prev->next = new;
}

/**
 * minios_list_add - add a new entry
 * @new: new entry to be added
 * @head: list head to add it after
 *
 * Insert a new entry after the specified head.
 * This is good for implementing stacks.
 */
static __inline__ void minios_list_add(struct minios_list_head *new, struct minios_list_head *head)
{
	__minios_list_add(new, head, head->next);
}

/**
 * minios_list_add_tail - add a new entry
 * @new: new entry to be added
 * @head: list head to add it before
 *
 * Insert a new entry before the specified head.
 * This is useful for implementing queues.
 */
static __inline__ void minios_list_add_tail(struct minios_list_head *new, struct minios_list_head *head)
{
	__minios_list_add(new, head->prev, head);
}

/*
 * Delete a list entry by making the prev/next entries
 * point to each other.
 *
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 */
static __inline__ void __minios_list_del(struct minios_list_head * prev,
				  struct minios_list_head * next)
{
	next->prev = prev;
	prev->next = next;
}

/**
 * minios_list_del - deletes entry from list.
 * @entry: the element to delete from the list.
 * Note: minios_list_empty on entry does not return true after this, the entry is in an undefined state.
 */
static __inline__ void minios_list_del(struct minios_list_head *entry)
{
	__minios_list_del(entry->prev, entry->next);
}

/**
 * minios_list_del_init - deletes entry from list and reinitialize it.
 * @entry: the element to delete from the list.
 */
static __inline__ void minios_list_del_init(struct minios_list_head *entry)
{
	__minios_list_del(entry->prev, entry->next);
	MINIOS_INIT_LIST_HEAD(entry); 
}

/**
 * minios_list_empty - tests whether a list is empty
 * @head: the list to test.
 */
static __inline__ int minios_list_empty(struct minios_list_head *head)
{
	return head->next == head;
}

/**
 * minios_list_splice - join two lists
 * @list: the new list to add.
 * @head: the place to add it in the first list.
 */
static __inline__ void minios_list_splice(struct minios_list_head *list, struct minios_list_head *head)
{
	struct minios_list_head *first = list->next;

	if (first != list) {
		struct minios_list_head *last = list->prev;
		struct minios_list_head *at = head->next;

		first->prev = head;
		head->next = first;

		last->next = at;
		at->prev = last;
	}
}

/**
 * minios_list_entry - get the struct for this entry
 * @ptr:	the &struct minios_list_head pointer.
 * @type:	the type of the struct this is embedded in.
 * @member:	the name of the minios_list_struct within the struct.
 */
#define minios_list_entry(ptr, type, member) \
	((type *)((char *)(ptr)-(unsigned long)(&((type *)0)->member)))

/**
 * minios_list_for_each	-	iterate over a list
 * @pos:	the &struct minios_list_head to use as a loop counter.
 * @head:	the head for your list.
 */
#define minios_list_for_each(pos, head) \
	for (pos = (head)->next; pos != (head); pos = pos->next)
        	
/**
 * minios_list_for_each_safe	-	iterate over a list safe against removal of list entry
 * @pos:	the &struct minios_list_head to use as a loop counter.
 * @n:		another &struct minios_list_head to use as temporary storage
 * @head:	the head for your list.
 */
#define minios_list_for_each_safe(pos, n, head) \
	for (pos = (head)->next, n = pos->next; pos != (head); \
		pos = n, n = pos->next)

/**
 * minios_list_for_each_entry	-	iterate over list of given type
 * @pos:	the type * to use as a loop counter.
 * @head:	the head for your list.
 * @member:	the name of the minios_list_struct within the struct.
 */
#define minios_list_for_each_entry(pos, head, member)				\
	for (pos = minios_list_entry((head)->next, typeof(*pos), member);	\
	     &pos->member != (head); 					\
	     pos = minios_list_entry(pos->member.next, typeof(*pos), member))

/**
 * minios_list_for_each_entry_safe - iterate over list of given type safe against removal of list entry
 * @pos:	the type * to use as a loop counter.
 * @n:		another type * to use as temporary storage
 * @head:	the head for your list.
 * @member:	the name of the minios_list_struct within the struct.
 */
#define minios_list_for_each_entry_safe(pos, n, head, member)			\
	for (pos = minios_list_entry((head)->next, typeof(*pos), member),	\
		n = minios_list_entry(pos->member.next, typeof(*pos), member);	\
	     &pos->member != (head); 					\
	     pos = n, n = minios_list_entry(n->member.next, typeof(*n), member))
#endif /* _LINUX_LIST_H */

