#ifndef __DMI_H__
#define __DMI_H__

enum dmi_field {
	DMI_NONE,
	DMI_BIOS_VENDOR,
	DMI_BIOS_VERSION,
	DMI_BIOS_DATE,
	DMI_SYS_VENDOR,
	DMI_PRODUCT_NAME,
	DMI_PRODUCT_VERSION,
	DMI_BOARD_VENDOR,
	DMI_BOARD_NAME,
	DMI_BOARD_VERSION,
	DMI_STRING_MAX,
};

/*
 *	DMI callbacks for problem boards
 */
struct dmi_strmatch {
	u8 slot;
	char *substr;
};

struct dmi_system_id {
	int (*callback)(struct dmi_system_id *);
	char *ident;
	struct dmi_strmatch matches[4];
	void *driver_data;
};

#define DMI_MATCH(a,b)	{ a, b }

extern int dmi_check_system(struct dmi_system_id *list);
extern char * dmi_get_system_info(int field);
extern void dmi_scan_machine(void);
extern int dmi_get_table(u32 *base, u32 *len);

#endif	/* __DMI_H__ */
