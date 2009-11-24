/*
 * ELF relocation code (not used by xen kernel right now).
 */

#include "libelf-private.h"

/* ------------------------------------------------------------------------ */

static const char *rel_names_i386[] = {
    "R_386_NONE",
    "R_386_32",
    "R_386_PC32",
    "R_386_GOT32",
    "R_386_PLT32",
    "R_386_COPY",
    "R_386_GLOB_DAT",
    "R_386_JMP_SLOT",
    "R_386_RELATIVE",
    "R_386_GOTOFF",
    "R_386_GOTPC",
    "R_386_32PLT",
    "R_386_TLS_TPOFF",
    "R_386_TLS_IE",
    "R_386_TLS_GOTIE",
    "R_386_TLS_LE",
    "R_386_TLS_GD",
    "R_386_TLS_LDM",
    "R_386_16",
    "R_386_PC16",
    "R_386_8",
    "R_386_PC8",
    "R_386_TLS_GD_32",
    "R_386_TLS_GD_PUSH",
    "R_386_TLS_GD_CALL",
    "R_386_TLS_GD_POP",
    "R_386_TLS_LDM_32",
    "R_386_TLS_LDM_PUSH",
    "R_386_TLS_LDM_CALL",
    "R_386_TLS_LDM_POP",
    "R_386_TLS_LDO_32",
    "R_386_TLS_IE_32",
    "R_386_TLS_LE_32",
    "R_386_TLS_DTPMOD32",
    "R_386_TLS_DTPOFF32",
    "R_386_TLS_TPOFF32",
};

static int elf_reloc_i386(struct elf_binary *elf, int type,
                          uint64_t addr, uint64_t value)
{
    void *ptr = elf_get_ptr(elf, addr);
    uint32_t *u32;

    switch ( type )
    {
    case 1 /* R_386_32 */ :
        u32 = ptr;
        *u32 += elf->reloc_offset;
        break;
    case 2 /* R_386_PC32 */ :
        /* nothing */
        break;
    default:
        return -1;
    }
    return 0;
}

/* ------------------------------------------------------------------------ */

static const char *rel_names_x86_64[] = {
    "R_X86_64_NONE",
    "R_X86_64_64",
    "R_X86_64_PC32",
    "R_X86_64_GOT32",
    "R_X86_64_PLT32",
    "R_X86_64_COPY",
    "R_X86_64_GLOB_DAT",
    "R_X86_64_JUMP_SLOT",
    "R_X86_64_RELATIVE",
    "R_X86_64_GOTPCREL",
    "R_X86_64_32",
    "R_X86_64_32S",
    "R_X86_64_16",
    "R_X86_64_PC16",
    "R_X86_64_8",
    "R_X86_64_PC8",
    "R_X86_64_DTPMOD64",
    "R_X86_64_DTPOFF64",
    "R_X86_64_TPOFF64",
    "R_X86_64_TLSGD",
    "R_X86_64_TLSLD",
    "R_X86_64_DTPOFF32",
    "R_X86_64_GOTTPOFF",
    "R_X86_64_TPOFF32",
};

static int elf_reloc_x86_64(struct elf_binary *elf, int type,
                            uint64_t addr, uint64_t value)
{
    void *ptr = elf_get_ptr(elf, addr);
    uint64_t *u64;
    uint32_t *u32;
    int32_t *s32;

    switch ( type )
    {
    case 1 /* R_X86_64_64 */ :
        u64 = ptr;
        value += elf->reloc_offset;
        *u64 = value;
        break;
    case 2 /* R_X86_64_PC32 */ :
        u32 = ptr;
        *u32 = value - addr;
        if ( *u32 != (uint32_t)(value - addr) )
        {
            elf_err(elf, "R_X86_64_PC32 overflow: 0x%" PRIx32
                    " != 0x%" PRIx32 "\n",
                    *u32, (uint32_t) (value - addr));
            return -1;
        }
        break;
    case 10 /* R_X86_64_32 */ :
        u32 = ptr;
        value += elf->reloc_offset;
        *u32 = value;
        if ( *u32 != value )
        {
            elf_err(elf, "R_X86_64_32 overflow: 0x%" PRIx32
                    " != 0x%" PRIx64 "\n",
                    *u32, value);
            return -1;
        }
        break;
    case 11 /* R_X86_64_32S */ :
        s32 = ptr;
        value += elf->reloc_offset;
        *s32 = value;
        if ( *s32 != (int64_t) value )
        {
            elf_err(elf, "R_X86_64_32S overflow: 0x%" PRIx32
                    " != 0x%" PRIx64 "\n",
                    *s32, (int64_t) value);
            return -1;
        }
        break;
    default:
        return -1;
    }
    return 0;
}

/* ------------------------------------------------------------------------ */

static struct relocs {
    const char **names;
    int count;
    int (*func) (struct elf_binary * elf, int type, uint64_t addr,
                 uint64_t value);
} relocs[] =
/* *INDENT-OFF* */
{
    [EM_386] = {
        .names = rel_names_i386,
        .count = sizeof(rel_names_i386) / sizeof(rel_names_i386[0]),
        .func = elf_reloc_i386,
    },
    [EM_X86_64] = {
        .names = rel_names_x86_64,
        .count = sizeof(rel_names_x86_64) / sizeof(rel_names_x86_64[0]),
        .func = elf_reloc_x86_64,
    }
};
/* *INDENT-ON* */

/* ------------------------------------------------------------------------ */

static const char *rela_name(int machine, int type)
{
    if ( machine > sizeof(relocs) / sizeof(relocs[0]) )
        return "unknown mach";
    if ( !relocs[machine].names )
        return "unknown mach";
    if ( type > relocs[machine].count )
        return "unknown rela";
    return relocs[machine].names[type];
}

static int elf_reloc_section(struct elf_binary *elf,
                             const elf_shdr * rels,
                             const elf_shdr * sect, const elf_shdr * syms)
{
    const void *ptr, *end;
    const elf_shdr *shdr;
    const elf_rela *rela;
    const elf_rel *rel;
    const elf_sym *sym;
    uint64_t s_type;
    uint64_t r_offset;
    uint64_t r_info;
    uint64_t r_addend;
    int r_type, r_sym;
    size_t rsize;
    uint64_t shndx, sbase, addr, value;
    const char *sname;
    int machine;

    machine = elf_uval(elf, elf->ehdr, e_machine);
    if ( (machine >= (sizeof(relocs) / sizeof(relocs[0]))) ||
         (relocs[machine].func == NULL) )
    {
        elf_err(elf, "%s: can't handle machine %d\n",
                __FUNCTION__, machine);
        return -1;
    }
    if ( elf_swap(elf) )
    {
        elf_err(elf, "%s: non-native byte order, relocation not supported\n",
                __FUNCTION__);
        return -1;
    }

    s_type = elf_uval(elf, rels, sh_type);
    rsize = (SHT_REL == s_type) ? elf_size(elf, rel) : elf_size(elf, rela);
    ptr = elf_section_start(elf, rels);
    end = elf_section_end(elf, rels);

    for ( ; ptr < end; ptr += rsize )
    {
        switch ( s_type )
        {
        case SHT_REL:
            rel = ptr;
            r_offset = elf_uval(elf, rel, r_offset);
            r_info = elf_uval(elf, rel, r_info);
            r_addend = 0;
            break;
        case SHT_RELA:
            rela = ptr;
            r_offset = elf_uval(elf, rela, r_offset);
            r_info = elf_uval(elf, rela, r_info);
            r_addend = elf_uval(elf, rela, r_addend);
            break;
        default:
            /* can't happen */
            return -1;
        }
        if ( elf_64bit(elf) )
        {
            r_type = ELF64_R_TYPE(r_info);
            r_sym = ELF64_R_SYM(r_info);
        }
        else
        {
            r_type = ELF32_R_TYPE(r_info);
            r_sym = ELF32_R_SYM(r_info);
        }

        sym = elf_sym_by_index(elf, r_sym);
        shndx = elf_uval(elf, sym, st_shndx);
        switch ( shndx )
        {
        case SHN_UNDEF:
            sname = "*UNDEF*";
            sbase = 0;
            break;
        case SHN_COMMON:
            elf_err(elf, "%s: invalid section: %" PRId64 "\n",
                    __FUNCTION__, shndx);
            return -1;
        case SHN_ABS:
            sname = "*ABS*";
            sbase = 0;
            break;
        default:
            shdr = elf_shdr_by_index(elf, shndx);
            if ( shdr == NULL )
            {
                elf_err(elf, "%s: invalid section: %" PRId64 "\n",
                        __FUNCTION__, shndx);
                return -1;
            }
            sname = elf_section_name(elf, shdr);
            sbase = elf_uval(elf, shdr, sh_addr);
        }

        addr = r_offset;
        value = elf_uval(elf, sym, st_value);
        value += r_addend;

        if ( elf->log && (elf->verbose > 1) )
        {
            uint64_t st_name = elf_uval(elf, sym, st_name);
            const char *name = st_name ? elf->sym_strtab + st_name : "*NONE*";

            elf_msg(elf,
                    "%s: type %s [%d], off 0x%" PRIx64 ", add 0x%" PRIx64 ","
                    " sym %s [0x%" PRIx64 "], sec %s [0x%" PRIx64 "]"
                    "  ->  addr 0x%" PRIx64 " value 0x%" PRIx64 "\n",
                    __FUNCTION__, rela_name(machine, r_type), r_type, r_offset,
                    r_addend, name, elf_uval(elf, sym, st_value), sname, sbase,
                    addr, value);
        }

        if ( relocs[machine].func(elf, r_type, addr, value) == -1 )
        {
            elf_err(elf, "%s: unknown/unsupported reloc type %s [%d]\n",
                    __FUNCTION__, rela_name(machine, r_type), r_type);
            return -1;
        }
    }
    return 0;
}

int elf_reloc(struct elf_binary *elf)
{
    const elf_shdr *rels, *sect, *syms;
    uint64_t i, count, type;

    count = elf_shdr_count(elf);
    for ( i = 0; i < count; i++ )
    {
        rels = elf_shdr_by_index(elf, i);
        type = elf_uval(elf, rels, sh_type);
        if ( (type != SHT_REL) && (type != SHT_RELA) )
            continue;

        sect = elf_shdr_by_index(elf, elf_uval(elf, rels, sh_info));
        syms = elf_shdr_by_index(elf, elf_uval(elf, rels, sh_link));
        if ( NULL == sect || NULL == syms )
            continue;

        if ( !(elf_uval(elf, sect, sh_flags) & SHF_ALLOC) )
        {
            elf_msg(elf, "%s: relocations for %s, skipping\n",
                    __FUNCTION__, elf_section_name(elf, sect));
            continue;
        }

        elf_msg(elf, "%s: relocations for %s @ 0x%" PRIx64 "\n",
                __FUNCTION__, elf_section_name(elf, sect),
                elf_uval(elf, sect, sh_addr));
        if ( elf_reloc_section(elf, rels, sect, syms) != 0 )
            return -1;
    }
    return 0;
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
