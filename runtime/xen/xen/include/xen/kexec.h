#ifndef __XEN_KEXEC_H__
#define __XEN_KEXEC_H__

#include <public/kexec.h>
#include <asm/percpu.h>
#include <xen/elfcore.h>

typedef struct xen_kexec_reserve {
    unsigned long size;
    unsigned long start;
} xen_kexec_reserve_t;

extern xen_kexec_reserve_t kexec_crash_area;

/* We have space for 4 images to support atomic update
 * of images. This is important for CRASH images since
 * a panic can happen at any time...
 */

#define KEXEC_IMAGE_DEFAULT_BASE 0
#define KEXEC_IMAGE_CRASH_BASE   2
#define KEXEC_IMAGE_NR           4

int machine_kexec_load(int type, int slot, xen_kexec_image_t *image);
void machine_kexec_unload(int type, int slot, xen_kexec_image_t *image);
void machine_kexec_reserved(xen_kexec_reserve_t *reservation);
void machine_reboot_kexec(xen_kexec_image_t *image);
void machine_kexec(xen_kexec_image_t *image);
void kexec_crash(void);
void kexec_disable_iosapic(void);
void kexec_crash_save_cpu(void);
crash_xen_info_t *kexec_crash_save_info(void);
void machine_crash_shutdown(void);
int machine_kexec_get(xen_kexec_range_t *range);

/* vmcoreinfo stuff */
#define VMCOREINFO_BYTES           (4096)
#define VMCOREINFO_NOTE_NAME       "VMCOREINFO_XEN"
void arch_crash_save_vmcoreinfo(void);
void vmcoreinfo_append_str(const char *fmt, ...)
       __attribute__ ((format (printf, 1, 2)));
#define VMCOREINFO_PAGESIZE(value) \
       vmcoreinfo_append_str("PAGESIZE=%ld\n", value)
#define VMCOREINFO_SYMBOL(name) \
       vmcoreinfo_append_str("SYMBOL(%s)=%lx\n", #name, (unsigned long)&name)
#define VMCOREINFO_SYMBOL_ALIAS(alias, name) \
       vmcoreinfo_append_str("SYMBOL(%s)=%lx\n", #alias, (unsigned long)&name)
#define VMCOREINFO_STRUCT_SIZE(name) \
       vmcoreinfo_append_str("SIZE(%s)=%zu\n", #name, sizeof(struct name))
#define VMCOREINFO_OFFSET(name, field) \
       vmcoreinfo_append_str("OFFSET(%s.%s)=%lu\n", #name, #field, \
                             (unsigned long)offsetof(struct name, field))
#define VMCOREINFO_OFFSET_ALIAS(name, field, alias) \
       vmcoreinfo_append_str("OFFSET(%s.%s)=%lu\n", #name, #alias, \
                             (unsigned long)offsetof(struct name, field))

#endif /* __XEN_KEXEC_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
