/*
 * parse and load elf binaries
 */

#include "libelf-private.h"

/* ------------------------------------------------------------------------ */

int elf_init(struct elf_binary *elf, const char *image, size_t size)
{
    const elf_shdr *shdr;
    uint64_t i, count, section, offset;

    if ( !elf_is_elfbinary(image) )
    {
        elf_err(elf, "%s: not an ELF binary\n", __FUNCTION__);
        return -1;
    }

    memset(elf, 0, sizeof(*elf));
    elf->image = image;
    elf->size = size;
    elf->ehdr = (elf_ehdr *)image;
    elf->class = elf->ehdr->e32.e_ident[EI_CLASS];
    elf->data = elf->ehdr->e32.e_ident[EI_DATA];

    /* Sanity check phdr. */
    offset = elf_uval(elf, elf->ehdr, e_phoff) +
        elf_uval(elf, elf->ehdr, e_phentsize) * elf_phdr_count(elf);
    if ( offset > elf->size )
    {
        elf_err(elf, "%s: phdr overflow (off %" PRIx64 " > size %lx)\n",
                __FUNCTION__, offset, (unsigned long)elf->size);
        return -1;
    }

    /* Sanity check shdr. */
    offset = elf_uval(elf, elf->ehdr, e_shoff) +
        elf_uval(elf, elf->ehdr, e_shentsize) * elf_shdr_count(elf);
    if ( offset > elf->size )
    {
        elf_err(elf, "%s: shdr overflow (off %" PRIx64 " > size %lx)\n",
                __FUNCTION__, offset, (unsigned long)elf->size);
        return -1;
    }

    /* Find section string table. */
    section = elf_uval(elf, elf->ehdr, e_shstrndx);
    shdr = elf_shdr_by_index(elf, section);
    if ( shdr != NULL )
        elf->sec_strtab = elf_section_start(elf, shdr);

    /* Find symbol table and symbol string table. */
    count = elf_shdr_count(elf);
    for ( i = 0; i < count; i++ )
    {
        shdr = elf_shdr_by_index(elf, i);
        if ( elf_uval(elf, shdr, sh_type) != SHT_SYMTAB )
            continue;
        elf->sym_tab = shdr;
        shdr = elf_shdr_by_index(elf, elf_uval(elf, shdr, sh_link));
        if ( shdr == NULL )
        {
            elf->sym_tab = NULL;
            continue;
        }
        elf->sym_strtab = elf_section_start(elf, shdr);
        break;
    }

    return 0;
}

#ifndef __XEN__
void elf_set_logfile(struct elf_binary *elf, FILE * log, int verbose)
{
    elf->log = log;
    elf->verbose = verbose;
}
#else
void elf_set_verbose(struct elf_binary *elf)
{
    elf->verbose = 1;
}
#endif

/* Calculate the required additional kernel space for the elf image */
void elf_parse_bsdsyms(struct elf_binary *elf, uint64_t pstart)
{
    uint64_t sz;
    const elf_shdr *shdr;
    int i, type;

    if ( !elf->sym_tab )
        return;

    pstart = elf_round_up(elf, pstart);

    /* Space to store the size of the elf image */
    sz = sizeof(uint32_t);

    /* Space for the elf and elf section headers */
    sz += (elf_uval(elf, elf->ehdr, e_ehsize) +
           elf_shdr_count(elf) * elf_uval(elf, elf->ehdr, e_shentsize));
    sz = elf_round_up(elf, sz);

    /* Space for the symbol and string tables. */
    for ( i = 0; i < elf_shdr_count(elf); i++ )
    {
        shdr = elf_shdr_by_index(elf, i);
        type = elf_uval(elf, (elf_shdr *)shdr, sh_type);
        if ( (type == SHT_STRTAB) || (type == SHT_SYMTAB) )
            sz = elf_round_up(elf, sz + elf_uval(elf, shdr, sh_size));
    }

    elf->bsd_symtab_pstart = pstart;
    elf->bsd_symtab_pend   = pstart + sz;
}

static void elf_load_bsdsyms(struct elf_binary *elf)
{
    elf_ehdr *sym_ehdr;
    unsigned long sz;
    char *maxva, *symbase, *symtab_addr;
    elf_shdr *shdr;
    int i, type;

    if ( !elf->bsd_symtab_pstart )
        return;

#define elf_hdr_elm(_elf, _hdr, _elm, _val)     \
do {                                            \
    if ( elf_64bit(_elf) )                      \
        (_hdr)->e64._elm = _val;                \
    else                                        \
        (_hdr)->e32._elm = _val;                \
} while ( 0 )

    symbase = elf_get_ptr(elf, elf->bsd_symtab_pstart);
    symtab_addr = maxva = symbase + sizeof(uint32_t);

    /* Set up Elf header. */
    sym_ehdr = (elf_ehdr *)symtab_addr;
    sz = elf_uval(elf, elf->ehdr, e_ehsize);
    memcpy(sym_ehdr, elf->ehdr, sz);
    maxva += sz; /* no round up */

    elf_hdr_elm(elf, sym_ehdr, e_phoff, 0);
    elf_hdr_elm(elf, sym_ehdr, e_shoff, elf_uval(elf, elf->ehdr, e_ehsize));
    elf_hdr_elm(elf, sym_ehdr, e_phentsize, 0);
    elf_hdr_elm(elf, sym_ehdr, e_phnum, 0);

    /* Copy Elf section headers. */
    shdr = (elf_shdr *)maxva;
    sz = elf_shdr_count(elf) * elf_uval(elf, elf->ehdr, e_shentsize);
    memcpy(shdr, elf->image + elf_uval(elf, elf->ehdr, e_shoff), sz);
    maxva = (char *)(long)elf_round_up(elf, (long)maxva + sz);

    for ( i = 0; i < elf_shdr_count(elf); i++ )
    {
        type = elf_uval(elf, shdr, sh_type);
        if ( (type == SHT_STRTAB) || (type == SHT_SYMTAB) )
        {
             elf_msg(elf, "%s: shdr %i at 0x%p -> 0x%p\n", __func__, i,
                     elf_section_start(elf, shdr), maxva);
             sz = elf_uval(elf, shdr, sh_size);
             memcpy(maxva, elf_section_start(elf, shdr), sz);
             /* Mangled to be based on ELF header location. */
             elf_hdr_elm(elf, shdr, sh_offset, maxva - symtab_addr);
             maxva = (char *)(long)elf_round_up(elf, (long)maxva + sz);
        }
        shdr = (elf_shdr *)((long)shdr +
                            (long)elf_uval(elf, elf->ehdr, e_shentsize));
    }

    /* Write down the actual sym size. */
    *(uint32_t *)symbase = maxva - symtab_addr;

#undef elf_ehdr_elm
}

void elf_parse_binary(struct elf_binary *elf)
{
    const elf_phdr *phdr;
    uint64_t low = -1;
    uint64_t high = 0;
    uint64_t i, count, paddr, memsz;

    count = elf_uval(elf, elf->ehdr, e_phnum);
    for ( i = 0; i < count; i++ )
    {
        phdr = elf_phdr_by_index(elf, i);
        if ( !elf_phdr_is_loadable(elf, phdr) )
            continue;
        paddr = elf_uval(elf, phdr, p_paddr);
        memsz = elf_uval(elf, phdr, p_memsz);
        elf_msg(elf, "%s: phdr: paddr=0x%" PRIx64
                " memsz=0x%" PRIx64 "\n", __FUNCTION__, paddr, memsz);
        if ( low > paddr )
            low = paddr;
        if ( high < paddr + memsz )
            high = paddr + memsz;
    }
    elf->pstart = low;
    elf->pend = high;
    elf_msg(elf, "%s: memory: 0x%" PRIx64 " -> 0x%" PRIx64 "\n",
            __FUNCTION__, elf->pstart, elf->pend);
}

void elf_load_binary(struct elf_binary *elf)
{
    const elf_phdr *phdr;
    uint64_t i, count, paddr, offset, filesz, memsz;
    char *dest;

    count = elf_uval(elf, elf->ehdr, e_phnum);
    for ( i = 0; i < count; i++ )
    {
        phdr = elf_phdr_by_index(elf, i);
        if ( !elf_phdr_is_loadable(elf, phdr) )
            continue;
        paddr = elf_uval(elf, phdr, p_paddr);
        offset = elf_uval(elf, phdr, p_offset);
        filesz = elf_uval(elf, phdr, p_filesz);
        memsz = elf_uval(elf, phdr, p_memsz);
        dest = elf_get_ptr(elf, paddr);
        elf_msg(elf, "%s: phdr %" PRIu64 " at 0x%p -> 0x%p\n",
                __func__, i, dest, dest + filesz);
        memcpy(dest, elf->image + offset, filesz);
        memset(dest + filesz, 0, memsz - filesz);
    }

    elf_load_bsdsyms(elf);
}

void *elf_get_ptr(struct elf_binary *elf, unsigned long addr)
{
    return elf->dest + addr - elf->pstart;
}

uint64_t elf_lookup_addr(struct elf_binary * elf, const char *symbol)
{
    const elf_sym *sym;
    uint64_t value;

    sym = elf_sym_by_name(elf, symbol);
    if ( sym == NULL )
    {
        elf_err(elf, "%s: not found: %s\n", __FUNCTION__, symbol);
        return -1;
    }

    value = elf_uval(elf, sym, st_value);
    elf_msg(elf, "%s: symbol \"%s\" at 0x%" PRIx64 "\n", __FUNCTION__,
            symbol, value);
    return value;
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
