#ifndef _MACH_MPPARSE_H
#define _MACH_MPPARSE_H 1

static inline void mpc_oem_bus_info(struct mpc_config_bus *m, char *name, 
				struct mpc_config_translation *translation)
{
	Dprintk("Bus #%d is %s\n", m->mpc_busid, name);
}

static inline void mpc_oem_pci_bus(struct mpc_config_bus *m, 
				struct mpc_config_translation *translation)
{
}

int mps_oem_check(struct mp_config_table *mpc, char *oem, char *productid);
int acpi_madt_oem_check(char *oem_id, char *oem_table_id);

#endif
