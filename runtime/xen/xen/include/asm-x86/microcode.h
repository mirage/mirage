#ifndef ASM_X86__MICROCODE_H
#define ASM_X86__MICROCODE_H

#include <xen/percpu.h>

struct cpu_signature;
struct ucode_cpu_info;

struct microcode_ops {
    int (*microcode_resume_match)(int cpu, struct cpu_signature *nsig);
    int (*cpu_request_microcode)(int cpu, const void *buf, size_t size);
    int (*collect_cpu_info)(int cpu, struct cpu_signature *csig);
    int (*apply_microcode)(int cpu);
};

struct microcode_header_intel {
    unsigned int hdrver;
    unsigned int rev;
    unsigned int date;
    unsigned int sig;
    unsigned int cksum;
    unsigned int ldrver;
    unsigned int pf;
    unsigned int datasize;
    unsigned int totalsize;
    unsigned int reserved[3];
};

struct microcode_intel {
    struct microcode_header_intel hdr;
    unsigned int bits[0];
};

/* microcode format is extended from prescott processors */
struct extended_signature {
    unsigned int sig;
    unsigned int pf;
    unsigned int cksum;
};

struct extended_sigtable {
    unsigned int count;
    unsigned int cksum;
    unsigned int reserved[3];
    struct extended_signature sigs[0];
};

struct equiv_cpu_entry {
    uint32_t installed_cpu;
    uint32_t fixed_errata_mask;
    uint32_t fixed_errata_compare;
    uint16_t equiv_cpu;
    uint16_t reserved;
} __attribute__((packed));

struct microcode_header_amd {
    uint32_t data_code;
    uint32_t patch_id;
    uint8_t  mc_patch_data_id[2];
    uint8_t  mc_patch_data_len;
    uint8_t  init_flag;
    uint32_t mc_patch_data_checksum;
    uint32_t nb_dev_id;
    uint32_t sb_dev_id;
    uint16_t processor_rev_id;
    uint8_t  nb_rev_id;
    uint8_t  sb_rev_id;
    uint8_t  bios_api_rev;
    uint8_t  reserved1[3];
    uint32_t match_reg[8];
} __attribute__((packed));

struct microcode_amd {
    struct microcode_header_amd hdr;
    unsigned int mpb[0];
};

struct cpu_signature {
    unsigned int sig;
    unsigned int pf;
    unsigned int rev;
};

struct ucode_cpu_info {
    struct cpu_signature cpu_sig;
    union {
        struct microcode_intel *mc_intel;
        struct microcode_amd *mc_amd;
        void *mc_valid;
    } mc;
};

DECLARE_PER_CPU(struct ucode_cpu_info, ucode_cpu_info);
extern const struct microcode_ops *microcode_ops;

#endif /* ASM_X86__MICROCODE_H */
