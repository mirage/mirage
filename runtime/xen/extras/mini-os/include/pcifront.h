#include <mini-os/types.h>
#include <xen/io/pciif.h>
struct pcifront_dev;
void pcifront_watches(void *opaque);
struct pcifront_dev *init_pcifront(char *nodename);
void pcifront_op(struct pcifront_dev *dev, struct xen_pci_op *op);
void pcifront_scan(struct pcifront_dev *dev, void (*fun)(unsigned int domain, unsigned int bus, unsigned slot, unsigned int fun));
int pcifront_conf_read(struct pcifront_dev *dev,
                       unsigned int dom,
                       unsigned int bus, unsigned int slot, unsigned long fun,
                       unsigned int off, unsigned int size, unsigned int *val);
int pcifront_conf_write(struct pcifront_dev *dev,
                        unsigned int dom,
                        unsigned int bus, unsigned int slot, unsigned long fun,
                        unsigned int off, unsigned int size, unsigned int val);
int pcifront_enable_msi(struct pcifront_dev *dev,
                        unsigned int dom,
                        unsigned int bus, unsigned int slot, unsigned long fun);
int pcifront_disable_msi(struct pcifront_dev *dev,
                         unsigned int dom,
                         unsigned int bus, unsigned int slot, unsigned long fun);
int pcifront_enable_msix(struct pcifront_dev *dev,
                         unsigned int dom,
                         unsigned int bus, unsigned int slot, unsigned long fun,
                         struct xen_msix_entry *entries, int n);
int pcifront_disable_msix(struct pcifront_dev *dev,
                          unsigned int dom,
                          unsigned int bus, unsigned int slot, unsigned long fun);
void shutdown_pcifront(struct pcifront_dev *dev);
