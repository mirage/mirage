/*
 * various helper functions to access elf structures
 */

#include "libelf-private.h"

/* ------------------------------------------------------------------------ */

uint64_t elf_access_unsigned(struct elf_binary * elf, const void *ptr,
                             uint64_t offset, size_t size)
{
    int need_swap = elf_swap(elf);
    const uint8_t *u8;
    const uint16_t *u16;
    const uint32_t *u32;
    const uint64_t *u64;

    switch ( size )
    {
    case 1:
        u8 = ptr + offset;
        return *u8;
    case 2:
        u16 = ptr + offset;
        return need_swap ? bswap_16(*u16) : *u16;
    case 4:
        u32 = ptr + offset;
        return need_swap ? bswap_32(*u32) : *u32;
    case 8:
        u64 = ptr + offset;
        return need_swap ? bswap_64(*u64) : *u64;
    default:
        return 0;
    }
}

int64_t elf_access_signed(struct elf_binary *elf, const void *ptr,
                          uint64_t offset, size_t size)
{
    int need_swap = elf_swap(elf);
    const int8_t *s8;
    const int16_t *s16;
    const int32_t *s32;
    const int64_t *s64;

    switch ( size )
    {
    case 1:
        s8 = ptr + offset;
        return *s8;
    case 2:
        s16 = ptr + offset;
        return need_swap ? bswap_16(*s16) : *s16;
    case 4:
        s32 = ptr + offset;
        return need_swap ? bswap_32(*s32) : *s32;
    case 8:
        s64 = ptr + offset;
        return need_swap ? bswap_64(*s64) : *s64;
    default:
        return 0;
    }
}

uint64_t elf_round_up(struct elf_binary *elf, uint64_t addr)
{
    int elf_round = (elf_64bit(elf) ? 8 : 4) - 1;

    return (addr + elf_round) & ~elf_round;
}

/* ------------------------------------------------------------------------ */

int elf_shdr_count(struct elf_binary *elf)
{
    return elf_uval(elf, elf->ehdr, e_shnum);
}

int elf_phdr_count(struct elf_binary *elf)
{
    return elf_uval(elf, elf->ehdr, e_phnum);
}

const elf_shdr *elf_shdr_by_name(struct elf_binary *elf, const char *name)
{
    uint64_t count = elf_shdr_count(elf);
    const elf_shdr *shdr;
    const char *sname;
    int i;

    for ( i = 0; i < count; i++ )
    {
        shdr = elf_shdr_by_index(elf, i);
        sname = elf_section_name(elf, shdr);
        if ( sname && !strcmp(sname, name) )
            return shdr;
    }
    return NULL;
}

const elf_shdr *elf_shdr_by_index(struct elf_binary *elf, int index)
{
    uint64_t count = elf_shdr_count(elf);
    const void *ptr;

    if ( index >= count )
        return NULL;

    ptr = (elf->image
           + elf_uval(elf, elf->ehdr, e_shoff)
           + elf_uval(elf, elf->ehdr, e_shentsize) * index);
    return ptr;
}

const elf_phdr *elf_phdr_by_index(struct elf_binary *elf, int index)
{
    uint64_t count = elf_uval(elf, elf->ehdr, e_phnum);
    const void *ptr;

    if ( index >= count )
        return NULL;

    ptr = (elf->image
           + elf_uval(elf, elf->ehdr, e_phoff)
           + elf_uval(elf, elf->ehdr, e_phentsize) * index);
    return ptr;
}

const char *elf_section_name(struct elf_binary *elf, const elf_shdr * shdr)
{
    if ( elf->sec_strtab == NULL )
        return "unknown";
    return elf->sec_strtab + elf_uval(elf, shdr, sh_name);
}

const void *elf_section_start(struct elf_binary *elf, const elf_shdr * shdr)
{
    return elf->image + elf_uval(elf, shdr, sh_offset);
}

const void *elf_section_end(struct elf_binary *elf, const elf_shdr * shdr)
{
    return elf->image
        + elf_uval(elf, shdr, sh_offset) + elf_uval(elf, shdr, sh_size);
}

const void *elf_segment_start(struct elf_binary *elf, const elf_phdr * phdr)
{
    return elf->image + elf_uval(elf, phdr, p_offset);
}

const void *elf_segment_end(struct elf_binary *elf, const elf_phdr * phdr)
{
    return elf->image
        + elf_uval(elf, phdr, p_offset) + elf_uval(elf, phdr, p_filesz);
}

const elf_sym *elf_sym_by_name(struct elf_binary *elf, const char *symbol)
{
    const void *ptr = elf_section_start(elf, elf->sym_tab);
    const void *end = elf_section_end(elf, elf->sym_tab);
    const elf_sym *sym;
    uint64_t info, name;

    for ( ; ptr < end; ptr += elf_size(elf, sym) )
    {
        sym = ptr;
        info = elf_uval(elf, sym, st_info);
        name = elf_uval(elf, sym, st_name);
        if ( ELF32_ST_BIND(info) != STB_GLOBAL )
            continue;
        if ( strcmp(elf->sym_strtab + name, symbol) )
            continue;
        return sym;
    }
    return NULL;
}

const elf_sym *elf_sym_by_index(struct elf_binary *elf, int index)
{
    const void *ptr = elf_section_start(elf, elf->sym_tab);
    const elf_sym *sym;

    sym = ptr + index * elf_size(elf, sym);
    return sym;
}

const char *elf_note_name(struct elf_binary *elf, const elf_note * note)
{
    return (void *)note + elf_size(elf, note);
}

const void *elf_note_desc(struct elf_binary *elf, const elf_note * note)
{
    int namesz = (elf_uval(elf, note, namesz) + 3) & ~3;

    return (void *)note + elf_size(elf, note) + namesz;
}

uint64_t elf_note_numeric(struct elf_binary *elf, const elf_note * note)
{
    const void *desc = elf_note_desc(elf, note);
    int descsz = elf_uval(elf, note, descsz);

    switch (descsz)
    {
    case 1:
    case 2:
    case 4:
    case 8:
        return elf_access_unsigned(elf, desc, 0, descsz);
    default:
        return 0;
    }
}
const elf_note *elf_note_next(struct elf_binary *elf, const elf_note * note)
{
    int namesz = (elf_uval(elf, note, namesz) + 3) & ~3;
    int descsz = (elf_uval(elf, note, descsz) + 3) & ~3;

    return (void *)note + elf_size(elf, note) + namesz + descsz;
}

/* ------------------------------------------------------------------------ */

int elf_is_elfbinary(const void *image)
{
    const Elf32_Ehdr *ehdr = image;

    return IS_ELF(*ehdr);
}

int elf_phdr_is_loadable(struct elf_binary *elf, const elf_phdr * phdr)
{
    uint64_t p_type = elf_uval(elf, phdr, p_type);
    uint64_t p_flags = elf_uval(elf, phdr, p_flags);

    return ((p_type == PT_LOAD) && (p_flags & (PF_W | PF_X)) != 0);
}

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
