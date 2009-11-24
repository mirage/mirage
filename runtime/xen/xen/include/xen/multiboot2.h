/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * Copyright IBM Corp. 2006, 2007
 *
 * Authors: Hollis Blanchard <hollisb@us.ibm.com>
 *          
 */

#ifndef _MULTIBOOT2_H_
#define _MULTIBOOT2_H_

/* How many bytes from the start of the file we search for the header.  */
#define MB2_HEADER_SEARCH           8192

/* The magic field should contain this.  */
#define MB2_HEADER_MAGIC            0xe85250d6

/* Passed from the bootloader to the kernel.  */
#define MB2_BOOTLOADER_MAGIC        0x36d76289

#define for_each_tag(_tag, _tags) \
    for ((_tag) = (_tags); \
            ((_tag)->key != MB2_TAG_END && (_tag)->key != 0); \
            (_tag) = (void *)(_tag) + (_tag)->len)

typedef uint32_t mb2_word;

struct mb2_header
{
  uint32_t magic;
};

struct mb2_tag_header
{
  uint32_t key;
  uint32_t len;
};

#define MB2_TAG_START     1
struct mb2_tag_start
{
  struct mb2_tag_header header;
  mb2_word size; /* Total size of all mb2 tags. */
};

#define MB2_TAG_NAME      2
struct mb2_tag_name
{
  struct mb2_tag_header header;
  char name[1];
};

#define MB2_TAG_MODULE    3
struct mb2_tag_module
{
  struct mb2_tag_header header;
  mb2_word addr;
  mb2_word size;
  unsigned char type[36];
  unsigned char cmdline[1];
};

#define MB2_TAG_MEMORY    4
struct mb2_tag_memory
{
  struct mb2_tag_header header;
  mb2_word addr;
  mb2_word size;
  mb2_word type;
};

#define MB2_TAG_UNUSED    5
struct mb2_tag_unused
{
  struct mb2_tag_header header;
};

#define MB2_TAG_END       0xffff
struct mb2_tag_end
{
  struct mb2_tag_header header;
};

#endif
