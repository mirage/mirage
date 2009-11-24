#ifndef __XEN_VERSION_H__
#define __XEN_VERSION_H__

const char *xen_compile_date(void);
const char *xen_compile_time(void);
const char *xen_compile_by(void);
const char *xen_compile_domain(void);
const char *xen_compile_host(void);
const char *xen_compiler(void);
unsigned int xen_major_version(void);
unsigned int xen_minor_version(void);
const char *xen_extra_version(void);
const char *xen_changeset(void);
const char *xen_banner(void);

#endif /* __XEN_VERSION_H__ */
