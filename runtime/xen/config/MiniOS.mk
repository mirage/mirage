include $(XEN_ROOT)/config/StdGNU.mk
include $(XEN_ROOT)/extras/mini-os/Config.mk
CFLAGS += $(DEF_CFLAGS) $(ARCH_CFLAGS)
CPPFLAGS += $(DEF_CPPFLAGS) $(ARCH_CPPFLAGS) $(extra_incl)
ASFLAGS += $(DEF_ASFLAGS) $(ARCH_ASFLAGS)
LDFLAGS += $(DEF_LDFLAGS) $(ARCH_LDFLAGS)

# Override settings for this OS
PTHREAD_LIBS =
