/*-*-c-*- ************************************************************
 * Copyright (C) 2001-2005,  Simon Kagstrom
 *
 * Filename:      ght_hash_table.h.in
 * Description:   The definitions used in the hash table.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 *
 * $Id: ght_hash_table.h.in 15761 2007-07-15 06:08:52Z ska $
 *
 ********************************************************************/

/**
 * @file
 * libghthash is a generic hash table used for storing arbitrary
 * data.
 *
 * Libghthash really stores pointers to data - the hash
 * table knows nothing about the actual type of the data.
 *
 * A simple example to get started can be found in the
 * <TT>example/simple.c</TT> file found in the distribution.
 * <TT>hash_test.c</TT> provides a more comlpete example.
 *
 * Some basic properties of the hash table are:
 *
 * - Both the data stored and the keys are of void type, which
 *   means that you can store any kind of data.
 *
 * - The only functions you probably will need to start is:
 *   - ght_create(), which creates a new hash table.
 *   - ght_insert(), which inserts a new entry into a table.
 *   - ght_get(), which searches for an entry.
 *   - ght_remove(), which removes and entry.
 *   - ght_finalize(), which destroys a hash table.
 *
 * - Inserting entries is done without first creating a key,
 *   i.e. you insert with the data, the datasize, the key and the
 *   key size directly.
 *
 * - The hash table copies the key data when inserting new
 *   entries. This means that you should <I>not</I> malloc() the key
 *   before inserting a new entry.
 *
 */
#ifndef GHT_HASH_TABLE_H
#define GHT_HASH_TABLE_H

#include <stdlib.h>                    /* size_t */

#ifdef __cplusplus
extern "C" {
#endif

#define GHT_HEURISTICS_NONE          0
#define GHT_HEURISTICS_TRANSPOSE     1
#define GHT_HEURISTICS_MOVE_TO_FRONT 2
#define GHT_AUTOMATIC_REHASH         4

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

/** unsigned 32 bit integer. */
typedef unsigned int ght_uint32_t;

/**
 * The structure for hash keys. You should not care about this
 * structure unless you plan to write your own hash functions.
 */
typedef struct s_hash_key
{
  unsigned int i_size;       /**< The size in bytes of the key p_key */
  const void *p_key;         /**< A pointer to the key. */
} ght_hash_key_t;

/*
 * The structure for hash entries.
 *
 * LOCK: Should be possible to do somewhat atomically
 */
typedef struct s_hash_entry
{
  void *p_data;

  struct s_hash_entry *p_next;
  struct s_hash_entry *p_prev;
  struct s_hash_entry *p_older;
  struct s_hash_entry *p_newer;
  ght_hash_key_t key;

} ght_hash_entry_t;

/*
 * The structure used in iterations. You should not care about the
 * contents of this, it will be filled and updated by ght_first() and
 * ght_next().
 */
typedef struct
{
  ght_hash_entry_t *p_entry; /* The current entry */
  ght_hash_entry_t *p_next;  /* The next entry */
} ght_iterator_t;

/**
 * Definition of the hash function pointers. @c ght_fn_hash_t should be
 * used when implementing new hash functions. Look at the supplied
 * hash functions, like @c ght_one_at_a_time_hash(), for examples of hash
 * functions.
 *
 * @param p_key the key to calculate the hash value for.
 *
 * @return a 32 bit hash value.
 *
 * @see @c ght_one_at_a_time_hash(), @c ght_rotating_hash(),
 *      @c ght_crc_hash()
 */
typedef ght_uint32_t (*ght_fn_hash_t)(ght_hash_key_t *p_key);

/**
 * Definition of the allocation function pointers. This is simply the
 * same definition as @c malloc().
 *
 * @param size the size to allocate. This will always be
 *        <TT>sizeof(ght_hash_entry_t) + key_size</TT>.
 *
 * @return a pointer to the allocated region, or NULL if the
 *         allocation failed.
 */
typedef void *(*ght_fn_alloc_t)(size_t size);

/**
 * Definition of the deallocation function pointers. This is simply the
 * same definition as @c free().
 *
 * @param ptr a pointer to the region to free.
 */
typedef void (*ght_fn_free_t)(void *ptr);

/**
 * Definition of bounded bucket free callback function pointers.
 *
 * The keys is passed back as const, since it was accepted by ght_insert()
 * as const, but if the callback function knows that a non-const pointer
 * was passed in, it can cast it back to non-const.
 */
typedef void (*ght_fn_bucket_free_callback_t)(void *data, const void *key);

/**
 * The hash table structure.
 */
typedef struct
{
  unsigned int i_items;              /**< The current number of items in the table */
  unsigned int i_size;               /**< The number of buckets */
  ght_fn_hash_t fn_hash;             /**< The hash function used */
  ght_fn_alloc_t fn_alloc;           /**< The function used for allocating entries */
  ght_fn_free_t fn_free;             /**< The function used for freeing entries */
  ght_fn_bucket_free_callback_t fn_bucket_free; /**< The function called when a bucket overflows */
  int i_heuristics;                  /**< The type of heuristics used */
  int i_automatic_rehash;            /**< TRUE if automatic rehashing is used */

  /* private: */
  ght_hash_entry_t **pp_entries;
  int *p_nr;                         /* The number of entries in each bucket */
  int i_size_mask;                   /* The number of bits used in the size */
  unsigned int bucket_limit;

  ght_hash_entry_t *p_oldest;        /* The entry inserted the earliest. */
  ght_hash_entry_t *p_newest;        /* The entry inserted the latest. */
} ght_hash_table_t;

/**
 * Create a new hash table. The number of buckets should be about as
 * big as the number of elements you wish to store in the table for
 * good performance. The number of buckets is rounded to the next
 * higher power of two.
 *
 * The hash table is created with @c ght_one_at_a_time_hash() as hash
 * function, automatic rehashing disabled, @c malloc() as the memory
 * allocator and no heuristics.
 *
 * @param i_size the number of buckets in the hash table. Giving a
 *        non-power of two here will round the size up to the next
 *        power of two.
 *
 * @see ght_set_hash(), ght_set_heuristics(), ght_set_rehash(),
 * @see ght_set_alloc()
 *
 * @return a pointer to the hash table or NULL upon error.
 */
ght_hash_table_t *ght_create(unsigned int i_size);

/**
 * Set the allocation/freeing functions to use for a hash table. The
 * allocation function will only be called when a new entry is
 * inserted.
 *
 * The allocation size will always be <TT>sizeof(ght_hash_entry_t) +
 * sizeof(ght_hash_key_t) + key_size</TT>. The actual size varies with
 * the key size.
 *
 * If this function is <I>not</I> called, @c malloc() and @c free()
 * will be used for allocation and freeing.
 *
 * @warning Always call this function <I>before</I> any entries are
 *          inserted into the table. Otherwise, the new free() might be called
 *          on something that were allocated with another allocation function.
 *
 * @param p_ht the hash table to set the memory management functions
 *        for.
 * @param fn_alloc the allocation function to use.
 * @param fn_free the deallocation function to use.
 */
void ght_set_alloc(ght_hash_table_t *p_ht, ght_fn_alloc_t fn_alloc, ght_fn_free_t fn_free);

/**
 * Set the hash function to use for a hash table.
 *
 * @warning Always call this function before any entries are inserted
 *          into the table. Otherwise, it will not be possible to find entries
 *          that were inserted before this function was called.
 *
 * @param p_ht the hash table set the hash function for.
 * @param fn_hash the hash function.
 */
void ght_set_hash(ght_hash_table_t *p_ht, ght_fn_hash_t fn_hash);

/**
 * Set the heuristics to use for the hash table. The possible values are:
 *
 * - <TT>GHT_HEURISTICS_NONE</TT>: Don't use any heuristics.
 * - <TT>0</TT>: Same as above.
 * - <TT>GHT_HEURISTICS_TRANSPOSE</TT>: Use transposing heuristics. An
 *   accessed element will move one step up in the bucket-list with this
 *   method.
 * - <TT>GHT_HEURISTICS_MOVE_TO_FRONT</TT>: Use move-to-front
 *   heuristics. An accessed element will be moved the front of the
 *   bucket list with this method.
 *
 * @param p_ht the hash table set the heuristics for.
 * @param i_heuristics the heuristics to use.
 */
void ght_set_heuristics(ght_hash_table_t *p_ht, int i_heuristics);

/**
 * Enable or disable automatic rehashing.
 *
 * With automatic rehashing, the table will rehash itself when the
 * number of elements in the table are twice as many as the number of
 * buckets. You should note that automatic rehashing will cause your
 * application to be really slow when the table is rehashing (which
 * might happen at times when you need speed), you should therefore be
 * careful with this in time-constrainted applications.
 *
 * @param p_ht the hash table to set rehashing for.
 * @param b_rehash TRUE if rehashing should be used or FALSE if it
 *        should not be used.
 */
void ght_set_rehash(ght_hash_table_t *p_ht, int b_rehash);

/**
 * Enable or disable bounded buckets.
 *
 * With bounded buckets, the hash table will act as a cache, only
 * holding a fixed number of elements per bucket. @a limit specifies
 * the limit of elements per bucket. When inserting elements with @a
 * ght_insert into a bounded table, the last entry in the bucket chain
 * will be free:d. libghthash will then call the callback function @a
 * fn, which allow the user of the library to dispose of the key and data.
 *
 * Bounded buckets are disabled by default.
 *
 * @param p_ht the hash table to set the bounded buckets for.
 * @param limit the maximum number of items in each bucket. If @a
 * limit is set to 0, bounded buckets are disabled.
 * @param fn a pointer to a callback function that is called when an
 * entry is free:d. The function should return 0 if the entry can be
 * freed, or -1 otherwise. If -1 is returned, libghthash will select
 * the second last entry and call the callback with that instead.
 */
void ght_set_bounded_buckets(ght_hash_table_t *p_ht, unsigned int limit, ght_fn_bucket_free_callback_t fn);


/**
 * Get the size (the number of items) of the hash table.
 *
 * @param p_ht the hash table to get the size for.
 *
 * @return the number of items in the hash table.
 */
unsigned int ght_size(ght_hash_table_t *p_ht);

/**
 * Get the table size (the number of buckets) of the hash table.
 *
 * @param p_ht the hash table to get the table size for.
 *
 * @return the number of buckets in the hash table.
 */
unsigned int ght_table_size(ght_hash_table_t *p_ht);


/**
 * Insert an entry into the hash table. Prior to inserting anything,
 * make sure that the table is created with ght_create(). If an
 * element with the same key as this one already exists in the table,
 * the insertion will fail and -1 is returned.
 *
 * A typical example is shown below, where the string "blabla"
 * (including the '\0'-terminator) is used as a key for the integer
 * 15.
 *
 * <PRE>
 * ght_hash_table_t *p_table;
 * char *p_key_data;
 * int *p_data;
 * int ret;
 *
 * [Create p_table etc...]
 * p_data = malloc(sizeof(int));
 * p_key_data = "blabla";
 * *p_data = 15;
 *
 * ret = ght_insert(p_table,
 *                  p_data,
 *                  sizeof(char)*(strlen(p_key_data)+1), p_key_data);
 * </PRE>
 *
 * @param p_ht the hash table to insert into.
 * @param p_entry_data the data to insert.
 * @param i_key_size the size of the key to associate the data with (in bytes).
 * @param p_key_data the key to use. The value will be copied, and it
 *                   is therefore OK to use a stack-allocated entry here.
 *
 * @return 0 if the element could be inserted, -1 otherwise.
 */
int ght_insert(ght_hash_table_t *p_ht,
	       void *p_entry_data,
	       unsigned int i_key_size, const void *p_key_data);

/**
 * Replace an entry in the hash table. This function will return an
 * error if the entry to be replaced does not exist, i.e. it cannot be
 * used to insert new entries. Replacing an entry does not affect its
 * iteration order.
 *
 * @param p_ht the hash table to search in.
 * @param p_entry_data the new data for the key.
 * @param i_key_size the size of the key to search with (in bytes).
 * @param p_key_data the key to search for.
 *
 * @return a pointer to the <I>old</I> value or NULL if the operation failed.
 */
void *ght_replace(ght_hash_table_t *p_ht,
		  void *p_entry_data,
		  unsigned int i_key_size, const void *p_key_data);


/**
 * Lookup an entry in the hash table. The entry is <I>not</I> removed from
 * the table.
 *
 * @param p_ht the hash table to search in.
 * @param i_key_size the size of the key to search with (in bytes).
 * @param p_key_data the key to search for.
 *
 * @return a pointer to the found entry or NULL if no entry could be found.
 */
void *ght_get(ght_hash_table_t *p_ht,
	      unsigned int i_key_size, const void *p_key_data);

/**
 * Remove an entry from the hash table. The entry is removed from the
 * table, but not freed (that is, the data stored is not freed).
 *
 * @param p_ht the hash table to use.
 * @param i_key_size the size of the key to search with (in bytes).
 * @param p_key_data the key to search for.
 *
 * @return a pointer to the removed entry or NULL if the entry could be found.
 */
void *ght_remove(ght_hash_table_t *p_ht,
		 unsigned int i_key_size, const void *p_key_data);

/**
 * Return the first entry in the hash table. This function should be
 * used for iteration and is used together with ght_next(). The order
 * of the entries will be from the oldest inserted entry to the newest
 * inserted entry. If an entry is inserted during an iteration, the entry
 * might or might not occur in the iteration. Note that removal during
 * an iteration is only safe for the <I>current</I> entry or an entry
 * which has <I>already been iterated over</I>.
 *
 * The use of the ght_iterator_t allows for several concurrent
 * iterations, where you would use one ght_iterator_t for each
 * iteration. In threaded environments, you should still lock access
 * to the hash table for insertion and removal.
 *
 * A typical example might look as follows:
 * <PRE>
 * ght_hash_table_t *p_table;
 * ght_iterator_t iterator;
 * void *p_key;
 * void *p_e;
 *
 * [Create table etc...]
 * for(p_e = ght_first(p_table, &iterator, &p_key); p_e; p_e = ght_next(p_table, &iterator, &p_key))
 *   {
 *      [Do something with the current entry p_e and it's key p_key]
 *   }
 * </PRE>
 *
 * @param p_ht the hash table to iterate through.
 *
 * @param p_iterator the iterator to use. The value of the structure
 * is filled in by this function and may be stack allocated.
 *
 * @param pp_key a pointer to the pointer of the key (NULL if none).
 *
 * @return a pointer to the first entry in the table or NULL if there
 * are no entries.
 *
 *
 * @see ght_next()
 */
void *ght_first(ght_hash_table_t *p_ht, ght_iterator_t *p_iterator, const void **pp_key);

/**
 * See ght_first() detailed description. This function augments
 * ght_first() by providing a facility to get the size of the keys
 * also. This interface is beneficial for hashtables which use
 * variable length keys.
 *
 * @param p_ht the hash table to iterate through.
 *
 * @param p_iterator the iterator to use. The value of the structure
 * is filled in by this function and may be stack allocated.
 *
 * @param pp_key a pointer to the pointer of the key (NULL if none).
 *
 * @param size a pointer to the size of the key pointer to by pp_key.
 *
 * @return a pointer to the first entry in the table or NULL if there
 * are no entries.
 *
 *
 * @see ght_next()
 */

void *ght_first_keysize(ght_hash_table_t *p_ht, ght_iterator_t *p_iterator, const void **pp_key, unsigned int *size);

/**
 * Return the next entry in the hash table. This function should be
 * used for iteration, and must be called after ght_first().
 *
 * @warning calling this without first having called ght_first will
 * give undefined results (probably a crash), since p_iterator isn't
 * filled correctly.
 *
 * @param p_ht the hash table to iterate through.
 *
 * @param p_iterator the iterator to use.
 *
 * @param pp_key a pointer to the pointer of the key (NULL if none).
 *
 * @return a pointer to the next entry in the table or NULL if there
 * are no more entries in the table.
 *
 * @see ght_first()
 */
void *ght_next(ght_hash_table_t *p_ht, ght_iterator_t *p_iterator, const void **pp_key);

/**
 * This functions works just like ght_next() but also returns the
 * keysize. This is beneficial for users of the hash table which use
 * variable length keys.
 *
 * @warning calling this without first having called ght_first will
 * give undefined results (probably a crash), since p_iterator isn't
 * filled correctly.
 *
 * @param p_ht the hash table to iterate through.
 *
 * @param p_iterator the iterator to use.
 *
 * @param pp_key a pointer to the pointer of the key (NULL if none).
 * 
 * @param size a pointer to the size of the key pointer to by pp_key.
 *
 * @return a pointer to the next entry in the table or NULL if there
 * are no more entries in the table.
 *
 * @see ght_first_keysize()
 */

void *ght_next_keysize(ght_hash_table_t *p_ht, ght_iterator_t *p_iterator, const void **pp_key, unsigned int *size);

/**
 * Rehash the hash table.
 *
 * Rehashing will change the size of the hash table, retaining all
 * elements. This is very costly and should be avoided unless really
 * needed. If <TT>GHT_AUTOMATIC_REHASH</TT> is specified in the flag
 * parameter when ght_create() is called, the hash table is
 * automatically rehashed when the number of stored elements exceeds
 * two times the number of buckets in the table (making calls to this
 * function unessessary).
 *
 * @param p_ht the hash table to rehash.
 * @param i_size the new size of the table.
 *
 * @see ght_create()
 */
void ght_rehash(ght_hash_table_t *p_ht, unsigned int i_size);

/**
 * Free the hash table. ght_finalize() should typically be called
 * at the end of the program. Note that only the metadata and the keys
 * of the table is freed, not the entries. If you want to free the
 * entries when removing the table, the entries will have to be
 * manually freed before ght_finalize() is called like:
 *
 * <PRE>
 * ght_iterator_t iterator;
 * void *p_key;
 * void *p_e;
 *
 * for(p_e = ght_first(p_table, &iterator, &p_key); p_e; p_e = ght_next(p_table, &iterator, &p_key))
 *   {
 *     free(p_e);
 *   }
 *
 * ght_finalize(p_table);
 * </PRE>
 *
 * @param p_ht the table to remove.
 */
void ght_finalize(ght_hash_table_t *p_ht);

/* exported hash functions */

/**
 * One-at-a-time-hash. One-at-a-time-hash is a good hash function, and
 * is the default when ght_create() is called with NULL as the
 * fn_hash parameter. This was found in a DrDobbs article, see
 * http://burtleburtle.net/bob/hash/doobs.html
 *
 * @warning Don't call this function directly, it is only meant to be
 * used as a callback for the hash table.
 *
 * @see ght_fn_hash_t
 * @see ght_rotating_hash(), ght_crc_hash()
 */
ght_uint32_t ght_one_at_a_time_hash(ght_hash_key_t *p_key);

/**
 * Rotating hash. Not so good hash function. This was found in a
 * DrDobbs article, see http://burtleburtle.net/bob/hash/doobs.html
 *
 * @warning Don't call this function directly, it is only meant to be
 * used as a callback for the hash table.
 *
 * @see ght_fn_hash_t
 * @see ght_one_at_a_time_hash(), ght_crc_hash()
 */
ght_uint32_t ght_rotating_hash(ght_hash_key_t *p_key);

/**
 * CRC32 hash. CRC32 hash is a good hash function. This came from Dru
 * Lemley <spambait@lemley.net>.
 *
 * @warning Don't call this function directly, it is only meant to be
 * used as a callback for the hash table.
 *
 * @see ght_fn_hash_t
 * @see ght_one_at_a_time_hash(), ght_rotating_hash()
 */
ght_uint32_t ght_crc_hash(ght_hash_key_t *p_key);

#ifdef USE_PROFILING
/**
 * Print some statistics about the table. Only available if the
 * library was compiled with <TT>USE_PROFILING</TT> defined.
 */
void ght_print(ght_hash_table_t *p_ht);
#endif

#ifdef __cplusplus
}
#endif

#endif /* GHT_HASH_TABLE_H */
