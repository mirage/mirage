ifneq ($(stubdom),y)
CTRL_SRCS-y += ia64/xc_ia64_stubs.c

GUEST_SRCS-y += ia64/xc_ia64_hvm_build.c
GUEST_SRCS-y += ia64/xc_ia64_linux_save.c
GUEST_SRCS-y += ia64/xc_ia64_linux_restore.c

GUEST_SRCS-y += ia64/xc_dom_ia64_util.c
GUEST_SRCS-y += ia64/dom_fw_acpi.c

GUEST_SRCS-y += ia64/xc_ia64_dom_fwloader.c

DOMFW_SRCS_BASE := dom_fw_common.c dom_fw_domu.c dom_fw_asm.S
endif
DOMFW_SRCS := $(addprefix ia64/, $(DOMFW_SRCS_BASE))
$(DOMFW_SRCS):
	ln -sf ../$(XEN_ROOT)/xen/arch/ia64/xen/$(@F) $@

# XXX kludge: libxc/Makefile doesn't understand .S.
GUEST_SRCS-y += $(patsubst %.S, %.c, $(DOMFW_SRCS))
%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@
%.opic: %.S
	$(CC) $(CPPFLAGS) -DPIC $(CFLAGS) -fPIC -c -o $@ $<


CFLAGS	+= -Iia64

DOMFW_ASM_HDRS_BASE := bundle.h dom_fw.h dom_fw_common.h dom_fw_domu.h
DOMFW_ASM_HDRS := $(addprefix ia64/asm/, $(DOMFW_ASM_HDRS_BASE))
$(DOMFW_ASM_HDRS): ia64/asm
	ln -sf ../../$(XEN_ROOT)/xen/include/asm-ia64/$(@F) $@
build: $(DOMFW_ASM_HDR)

.PHONY: mk-symlinks-acpi mk-symlinks-misc ia64-clean

IA64_HDR_DIRS := ia64/asm ia64/xen ia64/acpi ia64/acpi/platform
$(IA64_HDR_DIRS):
	mkdir -p $@

IA64_EMPTY_FILES := ia64/asm/acpi.h ia64/xen/list.h 
$(IA64_EMPTY_FILES): $(IA64_HDR_DIRS)
	echo "/* automatically created dummy empty header file. */" > $@

mk-symlinks-acpi: $(IA64_HDR_DIRS) $(IA64_EMPTY_FILES) $(DOMFW_ASM_HDRS)
	( cd ia64/acpi && ln -sf ../../$(XEN_ROOT)/xen/include/acpi/*.h .)
	( cd ia64/acpi/platform && ln -sf ../../../$(XEN_ROOT)/xen/include/acpi/platform/*.h .)
	( cd ia64/acpi/platform/ && ln -sf ../../aclinux.h .)
	( cd ia64/xen && ln -sf ../../$(XEN_ROOT)/xen/include/xen/acpi.h .)
mk-symlinks-misc: $(IA64_HDR_DIRS)
	( cd ia64/asm && ln -sf ../../$(XEN_ROOT)/xen/include/asm-ia64/linux-xen/asm/kregs.h .)
build: mk-symlinks-acpi mk-symlinks-misc

clean: ia64-clean
ia64-clean:
	rm -rf $(DOMFW_SRCS) $(DOMFW_ASM_HDRS) $(IA64_EMPTY_FILES) $(IA64_HDR_DIRS)
