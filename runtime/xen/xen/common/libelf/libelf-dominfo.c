/*
 * parse xen-specific informations out of elf kernel binaries.
 */

#include "libelf-private.h"

/* ------------------------------------------------------------------------ */
/* xen features                                                             */

static const char *const elf_xen_feature_names[] = {
    [XENFEAT_writable_page_tables] = "writable_page_tables",
    [XENFEAT_writable_descriptor_tables] = "writable_descriptor_tables",
    [XENFEAT_auto_translated_physmap] = "auto_translated_physmap",
    [XENFEAT_supervisor_mode_kernel] = "supervisor_mode_kernel",
    [XENFEAT_pae_pgdir_above_4gb] = "pae_pgdir_above_4gb"
};
static const int elf_xen_features =
sizeof(elf_xen_feature_names) / sizeof(elf_xen_feature_names[0]);

int elf_xen_parse_features(const char *features,
                           uint32_t *supported,
                           uint32_t *required)
{
    char feature[64];
    int pos, len, i;

    if ( features == NULL )
        return 0;

    for ( pos = 0; features[pos] != '\0'; pos += len )
    {
        memset(feature, 0, sizeof(feature));
        for ( len = 0;; len++ )
        {
            if ( len >= sizeof(feature)-1 )
                break;
            if ( features[pos + len] == '\0' )
                break;
            if ( features[pos + len] == '|' )
            {
                len++;
                break;
            }
            feature[len] = features[pos + len];
        }

        for ( i = 0; i < elf_xen_features; i++ )
        {
            if ( !elf_xen_feature_names[i] )
                continue;
            if ( (required != NULL) && (feature[0] == '!') )
            {
                /* required */
                if ( !strcmp(feature + 1, elf_xen_feature_names[i]) )
                {
                    elf_xen_feature_set(i, supported);
                    elf_xen_feature_set(i, required);
                    break;
                }
            }
            else
            {
                /* supported */
                if ( !strcmp(feature, elf_xen_feature_names[i]) )
                {
                    elf_xen_feature_set(i, supported);
                    break;
                }
            }
        }
        if ( i == elf_xen_features )
            return -1;
    }

    return 0;
}

/* ------------------------------------------------------------------------ */
/* xen elf notes                                                            */

int elf_xen_parse_note(struct elf_binary *elf,
                       struct elf_dom_parms *parms,
                       const elf_note *note)
{
/* *INDENT-OFF* */
    static const struct {
        char *name;
        int str;
    } note_desc[] = {
        [XEN_ELFNOTE_ENTRY] = { "ENTRY", 0},
        [XEN_ELFNOTE_HYPERCALL_PAGE] = { "HYPERCALL_PAGE", 0},
        [XEN_ELFNOTE_VIRT_BASE] = { "VIRT_BASE", 0},
        [XEN_ELFNOTE_INIT_P2M] = { "INIT_P2M", 0},
        [XEN_ELFNOTE_PADDR_OFFSET] = { "PADDR_OFFSET", 0},
        [XEN_ELFNOTE_HV_START_LOW] = { "HV_START_LOW", 0},
        [XEN_ELFNOTE_XEN_VERSION] = { "XEN_VERSION", 1},
        [XEN_ELFNOTE_GUEST_OS] = { "GUEST_OS", 1},
        [XEN_ELFNOTE_GUEST_VERSION] = { "GUEST_VERSION", 1},
        [XEN_ELFNOTE_LOADER] = { "LOADER", 1},
        [XEN_ELFNOTE_PAE_MODE] = { "PAE_MODE", 1},
        [XEN_ELFNOTE_FEATURES] = { "FEATURES", 1},
        [XEN_ELFNOTE_BSD_SYMTAB] = { "BSD_SYMTAB", 1},
        [XEN_ELFNOTE_SUSPEND_CANCEL] = { "SUSPEND_CANCEL", 0 },
    };
/* *INDENT-ON* */

    const char *str = NULL;
    uint64_t val = 0;
    int type = elf_uval(elf, note, type);

    if ( (type >= sizeof(note_desc) / sizeof(note_desc[0])) ||
         (note_desc[type].name == NULL) )
    {
        elf_msg(elf, "%s: unknown xen elf note (0x%x)\n",
                __FUNCTION__, type);
        return 0;
    }

    if ( note_desc[type].str )
    {
        str = elf_note_desc(elf, note);
        elf_msg(elf, "%s: %s = \"%s\"\n", __FUNCTION__,
                note_desc[type].name, str);
        parms->elf_notes[type].type = XEN_ENT_STR;
        parms->elf_notes[type].data.str = str;
    }
    else
    {
        val = elf_note_numeric(elf, note);
        elf_msg(elf, "%s: %s = 0x%" PRIx64 "\n", __FUNCTION__,
                note_desc[type].name, val);
        parms->elf_notes[type].type = XEN_ENT_LONG;
        parms->elf_notes[type].data.num = val;
    }
    parms->elf_notes[type].name = note_desc[type].name;

    switch ( type )
    {
    case XEN_ELFNOTE_LOADER:
        safe_strcpy(parms->loader, str);
        break;
    case XEN_ELFNOTE_GUEST_OS:
        safe_strcpy(parms->guest_os, str);
        break;
    case XEN_ELFNOTE_GUEST_VERSION:
        safe_strcpy(parms->guest_ver, str);
        break;
    case XEN_ELFNOTE_XEN_VERSION:
        safe_strcpy(parms->xen_ver, str);
        break;
    case XEN_ELFNOTE_PAE_MODE:
        if ( !strcmp(str, "yes") )
            parms->pae = 2 /* extended_cr3 */;
        if ( strstr(str, "bimodal") )
            parms->pae = 3 /* bimodal */;
        break;
    case XEN_ELFNOTE_BSD_SYMTAB:
        if ( !strcmp(str, "yes") )
            parms->bsd_symtab = 1;
        break;

    case XEN_ELFNOTE_VIRT_BASE:
        parms->virt_base = val;
        break;
    case XEN_ELFNOTE_ENTRY:
        parms->virt_entry = val;
        break;
    case XEN_ELFNOTE_INIT_P2M:
        parms->p2m_base = val;
        break;
    case XEN_ELFNOTE_PADDR_OFFSET:
        parms->elf_paddr_offset = val;
        break;
    case XEN_ELFNOTE_HYPERCALL_PAGE:
        parms->virt_hypercall = val;
        break;
    case XEN_ELFNOTE_HV_START_LOW:
        parms->virt_hv_start_low = val;
        break;

    case XEN_ELFNOTE_FEATURES:
        if ( elf_xen_parse_features(str, parms->f_supported,
                                    parms->f_required) )
            return -1;
        break;

    }
    return 0;
}

static int elf_xen_parse_notes(struct elf_binary *elf,
                               struct elf_dom_parms *parms,
                               const void *start, const void *end)
{
    int xen_elfnotes = 0;
    const elf_note *note;

    parms->elf_note_start = start;
    parms->elf_note_end   = end;
    for ( note = parms->elf_note_start;
          (void *)note < parms->elf_note_end;
          note = elf_note_next(elf, note) )
    {
        if ( strcmp(elf_note_name(elf, note), "Xen") )
            continue;
        if ( elf_xen_parse_note(elf, parms, note) )
            return -1;
        xen_elfnotes++;
    }
    return xen_elfnotes;
}

/* ------------------------------------------------------------------------ */
/* __xen_guest section                                                      */

int elf_xen_parse_guest_info(struct elf_binary *elf,
                             struct elf_dom_parms *parms)
{
    const char *h;
    char name[32], value[128];
    int len;

    h = parms->guest_info;
    while ( *h )
    {
        memset(name, 0, sizeof(name));
        memset(value, 0, sizeof(value));
        for ( len = 0;; len++, h++ )
        {
            if ( len >= sizeof(name)-1 )
                break;
            if ( *h == '\0' )
                break;
            if ( *h == ',' )
            {
                h++;
                break;
            }
            if ( *h == '=' )
            {
                h++;
                for ( len = 0;; len++, h++ )
                {
                    if ( len >= sizeof(value)-1 )
                        break;
                    if ( *h == '\0' )
                        break;
                    if ( *h == ',' )
                    {
                        h++;
                        break;
                    }
                    value[len] = *h;
                }
                break;
            }
            name[len] = *h;
        }
        elf_msg(elf, "%s: %s=\"%s\"\n", __FUNCTION__, name, value);

        /* strings */
        if ( !strcmp(name, "LOADER") )
            safe_strcpy(parms->loader, value);
        if ( !strcmp(name, "GUEST_OS") )
            safe_strcpy(parms->guest_os, value);
        if ( !strcmp(name, "GUEST_VER") )
            safe_strcpy(parms->guest_ver, value);
        if ( !strcmp(name, "XEN_VER") )
            safe_strcpy(parms->xen_ver, value);
        if ( !strcmp(name, "PAE") )
        {
            if ( !strcmp(value, "yes[extended-cr3]") )
                parms->pae = 2 /* extended_cr3 */;
            else if ( !strncmp(value, "yes", 3) )
                parms->pae = 1 /* yes */;
        }
        if ( !strcmp(name, "BSD_SYMTAB") )
            parms->bsd_symtab = 1;

        /* longs */
        if ( !strcmp(name, "VIRT_BASE") )
            parms->virt_base = strtoull(value, NULL, 0);
        if ( !strcmp(name, "VIRT_ENTRY") )
            parms->virt_entry = strtoull(value, NULL, 0);
        if ( !strcmp(name, "ELF_PADDR_OFFSET") )
            parms->elf_paddr_offset = strtoull(value, NULL, 0);
        if ( !strcmp(name, "HYPERCALL_PAGE") )
            parms->virt_hypercall = (strtoull(value, NULL, 0) << 12) +
                parms->virt_base;

        /* other */
        if ( !strcmp(name, "FEATURES") )
            if ( elf_xen_parse_features(value, parms->f_supported,
                                        parms->f_required) )
                return -1;
    }
    return 0;
}

/* ------------------------------------------------------------------------ */
/* sanity checks                                                            */

static int elf_xen_note_check(struct elf_binary *elf,
                              struct elf_dom_parms *parms)
{
    if ( (parms->elf_note_start == NULL) && (parms->guest_info == NULL) )
    {
        int machine = elf_uval(elf, elf->ehdr, e_machine);
        if ( (machine == EM_386) || (machine == EM_X86_64) )
        {
            elf_err(elf, "%s: ERROR: Not a Xen-ELF image: "
                    "No ELF notes or '__xen_guest' section found.\n",
                    __FUNCTION__);
            return -1;
        }
        return 0;
    }

    /* Check the contents of the Xen notes or guest string. */
    if ( ((strlen(parms->loader) == 0) ||
          strncmp(parms->loader, "generic", 7)) &&
         ((strlen(parms->guest_os) == 0) ||
          strncmp(parms->guest_os, "linux", 5)) )
    {
        elf_err(elf, "%s: ERROR: Will only load images built for the generic "
                "loader or Linux images", __FUNCTION__);
        return -1;
    }

    if ( (strlen(parms->xen_ver) == 0) ||
         strncmp(parms->xen_ver, "xen-3.0", 7) )
    {
        elf_err(elf, "%s: ERROR: Xen will only load images built "
                "for Xen v3.0\n", __FUNCTION__);
        return -1;
    }
    return 0;
}

static int elf_xen_addr_calc_check(struct elf_binary *elf,
                                   struct elf_dom_parms *parms)
{
    if ( (parms->elf_paddr_offset != UNSET_ADDR) &&
         (parms->virt_base == UNSET_ADDR) )
    {
        elf_err(elf, "%s: ERROR: ELF_PADDR_OFFSET set, VIRT_BASE unset\n",
                __FUNCTION__);
        return -1;
    }

    /* Initial guess for virt_base is 0 if it is not explicitly defined. */
    if ( parms->virt_base == UNSET_ADDR )
    {
        parms->virt_base = 0;
        elf_msg(elf, "%s: VIRT_BASE unset, using 0x%" PRIx64 "\n",
                __FUNCTION__, parms->virt_base);
    }

    /*
     * If we are using the legacy __xen_guest section then elf_pa_off
     * defaults to v_start in order to maintain compatibility with
     * older hypervisors which set padd in the ELF header to
     * virt_base.
     *
     * If we are using the modern ELF notes interface then the default
     * is 0.
     */
    if ( parms->elf_paddr_offset == UNSET_ADDR )
    {
        if ( parms->elf_note_start )
            parms->elf_paddr_offset = 0;
        else
            parms->elf_paddr_offset = parms->virt_base;
        elf_msg(elf, "%s: ELF_PADDR_OFFSET unset, using 0x%" PRIx64 "\n",
                __FUNCTION__, parms->elf_paddr_offset);
    }

    parms->virt_offset = parms->virt_base - parms->elf_paddr_offset;
    parms->virt_kstart = elf->pstart + parms->virt_offset;
    parms->virt_kend   = elf->pend   + parms->virt_offset;

    if ( parms->virt_entry == UNSET_ADDR )
        parms->virt_entry = elf_uval(elf, elf->ehdr, e_entry);

    if ( parms->bsd_symtab )
    {
        elf_parse_bsdsyms(elf, parms->virt_kend);
        if ( elf->bsd_symtab_pend )
            parms->virt_kend = elf->bsd_symtab_pend + parms->virt_offset;
    }

    elf_msg(elf, "%s: addresses:\n", __FUNCTION__);
    elf_msg(elf, "    virt_base        = 0x%" PRIx64 "\n", parms->virt_base);
    elf_msg(elf, "    elf_paddr_offset = 0x%" PRIx64 "\n", parms->elf_paddr_offset);
    elf_msg(elf, "    virt_offset      = 0x%" PRIx64 "\n", parms->virt_offset);
    elf_msg(elf, "    virt_kstart      = 0x%" PRIx64 "\n", parms->virt_kstart);
    elf_msg(elf, "    virt_kend        = 0x%" PRIx64 "\n", parms->virt_kend);
    elf_msg(elf, "    virt_entry       = 0x%" PRIx64 "\n", parms->virt_entry);
    elf_msg(elf, "    p2m_base         = 0x%" PRIx64 "\n", parms->p2m_base);

    if ( (parms->virt_kstart > parms->virt_kend) ||
         (parms->virt_entry < parms->virt_kstart) ||
         (parms->virt_entry > parms->virt_kend) ||
         (parms->virt_base > parms->virt_kstart) )
    {
        elf_err(elf, "%s: ERROR: ELF start or entries are out of bounds.\n",
                __FUNCTION__);
        return -1;
    }

    if ( (parms->p2m_base != UNSET_ADDR) &&
         (parms->p2m_base >= parms->virt_kstart) &&
         (parms->p2m_base < parms->virt_kend) )
    {
        elf_err(elf, "%s: ERROR: P->M table base is out of bounds.\n",
                __FUNCTION__);
        return -1;
    }

    return 0;
}

/* ------------------------------------------------------------------------ */
/* glue it all together ...                                                 */

int elf_xen_parse(struct elf_binary *elf,
                  struct elf_dom_parms *parms)
{
    const elf_shdr *shdr;
    const elf_phdr *phdr;
    int xen_elfnotes = 0;
    int i, count, rc;

    memset(parms, 0, sizeof(*parms));
    parms->virt_base = UNSET_ADDR;
    parms->virt_entry = UNSET_ADDR;
    parms->virt_hypercall = UNSET_ADDR;
    parms->virt_hv_start_low = UNSET_ADDR;
    parms->p2m_base = UNSET_ADDR;
    parms->elf_paddr_offset = UNSET_ADDR;

    /* Find and parse elf notes. */
    count = elf_phdr_count(elf);
    for ( i = 0; i < count; i++ )
    {
        phdr = elf_phdr_by_index(elf, i);
        if ( elf_uval(elf, phdr, p_type) != PT_NOTE )
            continue;

        /*
         * Some versions of binutils do not correctly set p_offset for
         * note segments.
         */
        if (elf_uval(elf, phdr, p_offset) == 0)
             continue;

        rc = elf_xen_parse_notes(elf, parms,
                                 elf_segment_start(elf, phdr),
                                 elf_segment_end(elf, phdr));
        if ( rc == -1 )
            return -1;

        xen_elfnotes += rc;
    }

    /*
     * Fall back to any SHT_NOTE sections if no valid note segments
     * were found.
     */
    if ( xen_elfnotes == 0 )
    {
        count = elf_shdr_count(elf);
        for ( i = 0; i < count; i++ )
        {
            shdr = elf_shdr_by_index(elf, i);

            if ( elf_uval(elf, shdr, sh_type) != SHT_NOTE )
                continue;

            rc = elf_xen_parse_notes(elf, parms,
                                     elf_section_start(elf, shdr),
                                     elf_section_end(elf, shdr));

            if ( rc == -1 )
                return -1;

            if ( xen_elfnotes == 0 && rc > 0 )
                elf_msg(elf, "%s: using notes from SHT_NOTE section\n", __FUNCTION__);

            xen_elfnotes += rc;
        }

    }

    /*
     * Finally fall back to the __xen_guest section.
     */
    if ( xen_elfnotes == 0 )
    {
        count = elf_shdr_count(elf);
        for ( i = 0; i < count; i++ )
        {
            shdr = elf_shdr_by_name(elf, "__xen_guest");
            if ( shdr )
            {
                parms->guest_info = elf_section_start(elf, shdr);
                parms->elf_note_start = NULL;
                parms->elf_note_end   = NULL;
                elf_msg(elf, "%s: __xen_guest: \"%s\"\n", __FUNCTION__,
                        parms->guest_info);
                elf_xen_parse_guest_info(elf, parms);
                break;
            }
        }
    }

    if ( elf_xen_note_check(elf, parms) != 0 )
        return -1;
    if ( elf_xen_addr_calc_check(elf, parms) != 0 )
        return -1;
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
