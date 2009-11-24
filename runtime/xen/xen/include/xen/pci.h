/******************************************************************************
 * pci.h
 * 
 * PCI access functions.
 */

#ifndef __XEN_PCI_H__
#define __XEN_PCI_H__

#include <xen/config.h>
#include <xen/types.h>
#include <xen/list.h>
#include <xen/spinlock.h>

/*
 * The PCI interface treats multi-function devices as independent
 * devices.  The slot/function address of each device is encoded
 * in a single byte as follows:
 *
 * 15:8 = bus
 *  7:3 = slot
 *  2:0 = function
 */
#define PCI_BUS(bdf)    (((bdf) >> 8) & 0xff)
#define PCI_SLOT(bdf)   (((bdf) >> 3) & 0x1f)
#define PCI_FUNC(bdf)   ((bdf) & 0x07)
#define PCI_DEVFN(d,f)  ((((d) & 0x1f) << 3) | ((f) & 0x07))
#define PCI_DEVFN2(bdf) ((bdf) & 0xff)
#define PCI_BDF(b,d,f)  ((((b) & 0xff) << 8) | PCI_DEVFN(d,f))
#define PCI_BDF2(b,df)  ((((b) & 0xff) << 8) | ((df) & 0xff))

#define MAX_MSIX_TABLE_ENTRIES  2048
#define MAX_MSIX_TABLE_PAGES    8
struct pci_dev_info {
    unsigned is_extfn;
    unsigned is_virtfn;
    struct {
        u8 bus;
        u8 devfn;
    } physfn;
};

struct pci_dev {
    struct list_head alldevs_list;
    struct list_head domain_list;

    struct list_head msi_list;
    int msix_table_refcnt[MAX_MSIX_TABLE_PAGES];
    int msix_table_idx[MAX_MSIX_TABLE_PAGES];
    spinlock_t msix_table_lock;

    struct domain *domain;
    const u8 bus;
    const u8 devfn;
    struct pci_dev_info info;
};

#define for_each_pdev(domain, pdev) \
    list_for_each_entry(pdev, &(domain->arch.pdev_list), domain_list)

/*
 * The pcidevs_lock protect alldevs_list, and the assignment for the 
 * devices, it also sync the access to the msi capability that is not
 * interrupt handling related (the mask bit register).
 */

extern spinlock_t pcidevs_lock;

enum {
    DEV_TYPE_PCIe_ENDPOINT,
    DEV_TYPE_PCIe_BRIDGE,       // PCIe root port, switch
    DEV_TYPE_PCIe2PCI_BRIDGE,   // PCIe-to-PCI/PCIx bridge
    DEV_TYPE_LEGACY_PCI_BRIDGE, // Legacy PCI bridge
    DEV_TYPE_PCI,
};

int scan_pci_devices(void);
int pdev_type(u8 bus, u8 devfn);
int find_upstream_bridge(u8 *bus, u8 *devfn, u8 *secbus);
struct pci_dev *alloc_pdev(u8 bus, u8 devfn);
void free_pdev(struct pci_dev *pdev);
struct pci_dev *pci_lock_pdev(int bus, int devfn);
struct pci_dev *pci_lock_domain_pdev(struct domain *d, int bus, int devfn);

void pci_release_devices(struct domain *d);
int pci_add_device(u8 bus, u8 devfn);
int pci_remove_device(u8 bus, u8 devfn);
int pci_add_device_ext(u8 bus, u8 devfn, struct pci_dev_info *info);
struct pci_dev *pci_get_pdev(int bus, int devfn);
struct pci_dev *pci_get_pdev_by_domain(struct domain *d, int bus, int devfn);

uint8_t pci_conf_read8(
    unsigned int bus, unsigned int dev, unsigned int func, unsigned int reg);
uint16_t pci_conf_read16(
    unsigned int bus, unsigned int dev, unsigned int func, unsigned int reg);
uint32_t pci_conf_read32(
    unsigned int bus, unsigned int dev, unsigned int func, unsigned int reg);
void pci_conf_write8(
    unsigned int bus, unsigned int dev, unsigned int func, unsigned int reg,
    uint8_t data);
void pci_conf_write16(
    unsigned int bus, unsigned int dev, unsigned int func, unsigned int reg,
    uint16_t data);
void pci_conf_write32(
    unsigned int bus, unsigned int dev, unsigned int func, unsigned int reg,
    uint32_t data);
uint32_t pci_conf_read(uint32_t cf8, uint8_t offset, uint8_t bytes);
void pci_conf_write(uint32_t cf8, uint8_t offset, uint8_t bytes, uint32_t data);
int pci_mmcfg_read(unsigned int seg, unsigned int bus,
                   unsigned int devfn, int reg, int len, u32 *value);
int pci_mmcfg_write(unsigned int seg, unsigned int bus,
                    unsigned int devfn, int reg, int len, u32 value);
int pci_find_cap_offset(u8 bus, u8 dev, u8 func, u8 cap);
int pci_find_next_cap(u8 bus, unsigned int devfn, u8 pos, int cap);
int pci_find_ext_capability(int seg, int bus, int devfn, int cap);

int msixtbl_pt_register(struct domain *d, int pirq, uint64_t gtable);
void msixtbl_pt_unregister(struct domain *d, int pirq);

#endif /* __XEN_PCI_H__ */
