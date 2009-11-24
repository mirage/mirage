#include <asm/kregs.h>
#include "xg_private.h"
#include "xenguest.h"
#include "xc_private.h"
#include "xc_elf.h"
#include "xc_efi.h"
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <zlib.h>
#include "xen/arch-ia64.h"
#include <xen/hvm/ioreq.h>
#include <xen/hvm/params.h>

static int
xc_ia64_copy_to_domain_pages(int xc_handle, uint32_t domid, void* src_page,
                             unsigned long dst_pfn, int nr_pages)
{
    // N.B. gva should be page aligned
    int i;

    for (i = 0; i < nr_pages; i++) {
        if (xc_copy_to_domain_page(xc_handle, domid, dst_pfn + i,
                                   src_page + (i << PAGE_SHIFT)))
            return -1;
    }

    return 0;
}

#define HOB_SIGNATURE         0x3436474953424f48        // "HOBSIG64"
#define GFW_HOB_START         ((4UL<<30)-(14UL<<20))    // 4G - 14M
#define GFW_HOB_SIZE          (1UL<<20)                 // 1M

typedef struct {
    unsigned long signature;
    unsigned int  type;
    unsigned int  length;
} HOB_GENERIC_HEADER;

/*
 * INFO HOB is the first data data in one HOB list
 * it contains the control information of the HOB list
 */
typedef struct {
    HOB_GENERIC_HEADER  header;
    unsigned long       length;    // current length of hob
    unsigned long       cur_pos;   // current poisiton of hob
    unsigned long       buf_size;  // size of hob buffer
} HOB_INFO;

typedef struct{
    unsigned long start;
    unsigned long size;
} hob_mem_t;

typedef enum {
    HOB_TYPE_INFO=0,
    HOB_TYPE_TERMINAL,
    HOB_TYPE_MEM,
    HOB_TYPE_PAL_BUS_GET_FEATURES_DATA,
    HOB_TYPE_PAL_CACHE_SUMMARY,
    HOB_TYPE_PAL_MEM_ATTRIB,
    HOB_TYPE_PAL_CACHE_INFO,
    HOB_TYPE_PAL_CACHE_PROT_INFO,
    HOB_TYPE_PAL_DEBUG_INFO,
    HOB_TYPE_PAL_FIXED_ADDR,
    HOB_TYPE_PAL_FREQ_BASE,
    HOB_TYPE_PAL_FREQ_RATIOS,
    HOB_TYPE_PAL_HALT_INFO,
    HOB_TYPE_PAL_PERF_MON_INFO,
    HOB_TYPE_PAL_PROC_GET_FEATURES,
    HOB_TYPE_PAL_PTCE_INFO,
    HOB_TYPE_PAL_REGISTER_INFO,
    HOB_TYPE_PAL_RSE_INFO,
    HOB_TYPE_PAL_TEST_INFO,
    HOB_TYPE_PAL_VM_SUMMARY,
    HOB_TYPE_PAL_VM_INFO,
    HOB_TYPE_PAL_VM_PAGE_SIZE,
    HOB_TYPE_NR_VCPU,
    HOB_TYPE_NVRAM,
    HOB_TYPE_MAX
} hob_type_t;

static int hob_init(void  *buffer ,unsigned long buf_size);
static int add_pal_hob(void* hob_buf);
static int add_mem_hob(void* hob_buf, unsigned long dom_mem_size);
static int add_vcpus_hob(void* hob_buf, unsigned long nr_vcpu);
static int add_nvram_hob(void* hob_buf, unsigned long nvram_addr);
static int build_hob(void* hob_buf, unsigned long hob_buf_size,
                     unsigned long dom_mem_size, unsigned long vcpus,
                     unsigned long nvram_addr);
static int load_hob(int xc_handle,uint32_t dom, void *hob_buf);

static int
xc_ia64_build_hob(int xc_handle, uint32_t dom,
                  unsigned long memsize, unsigned long vcpus,
                  unsigned long nvram_addr)
{
    char   *hob_buf;

    hob_buf = malloc(GFW_HOB_SIZE);
    if (hob_buf == NULL) {
        PERROR("Could not allocate hob");
        return -1;
    }

    if (build_hob(hob_buf, GFW_HOB_SIZE, memsize, vcpus, nvram_addr) < 0) {
        free(hob_buf);
        PERROR("Could not build hob");
        return -1;
    }

    if (load_hob(xc_handle, dom, hob_buf) < 0) {
        free(hob_buf);
        PERROR("Could not load hob");
        return -1;
    }
    free(hob_buf);
    return 0;

}

static int
hob_init(void *buffer, unsigned long buf_size)
{
    HOB_INFO *phit;
    HOB_GENERIC_HEADER *terminal;

    if (sizeof(HOB_INFO) + sizeof(HOB_GENERIC_HEADER) > buf_size) {
        // buffer too small
        return -1;
    }

    phit = (HOB_INFO*)buffer;
    phit->header.signature = HOB_SIGNATURE;
    phit->header.type = HOB_TYPE_INFO;
    phit->header.length = sizeof(HOB_INFO);
    phit->length = sizeof(HOB_INFO) + sizeof(HOB_GENERIC_HEADER);
    phit->cur_pos = 0;
    phit->buf_size = buf_size;

    terminal = (HOB_GENERIC_HEADER*)(buffer + sizeof(HOB_INFO));
    terminal->signature = HOB_SIGNATURE;
    terminal->type = HOB_TYPE_TERMINAL;
    terminal->length = sizeof(HOB_GENERIC_HEADER);

    return 0;
}

/*
 *  Add a new HOB to the HOB List.
 *
 *  hob_start  -  start address of hob buffer
 *  type       -  type of the hob to be added
 *  data       -  data of the hob to be added
 *  data_size  -  size of the data
 */
static int
hob_add(void* hob_start, int type, void* data, int data_size)
{
    HOB_INFO *phit;
    HOB_GENERIC_HEADER *newhob, *tail;

    phit = (HOB_INFO*)hob_start;

    if (phit->length + data_size > phit->buf_size) {
        // no space for new hob
        return -1;
    }

    //append new HOB
    newhob = (HOB_GENERIC_HEADER*)(hob_start + phit->length -
                                   sizeof(HOB_GENERIC_HEADER));
    newhob->signature = HOB_SIGNATURE;
    newhob->type = type;
    newhob->length = data_size + sizeof(HOB_GENERIC_HEADER);
    memcpy((void*)newhob + sizeof(HOB_GENERIC_HEADER), data, data_size);

    // append terminal HOB
    tail = (HOB_GENERIC_HEADER*)(hob_start + phit->length + data_size);
    tail->signature = HOB_SIGNATURE;
    tail->type = HOB_TYPE_TERMINAL;
    tail->length = sizeof(HOB_GENERIC_HEADER);

    // adjust HOB list length
    phit->length += sizeof(HOB_GENERIC_HEADER) + data_size;

    return 0;
}

static int
get_hob_size(void* hob_buf)
{
    HOB_INFO *phit = (HOB_INFO*)hob_buf;

    if (phit->header.signature != HOB_SIGNATURE) {
        PERROR("xc_get_hob_size:Incorrect signature");
        return -1;
    }
    return phit->length;
}

static int
build_hob(void* hob_buf, unsigned long hob_buf_size,
          unsigned long dom_mem_size, unsigned long vcpus,
          unsigned long nvram_addr)
{
    //Init HOB List
    if (hob_init(hob_buf, hob_buf_size) < 0) {
        PERROR("buffer too small");
        goto err_out;
    }

    if (add_mem_hob(hob_buf,dom_mem_size) < 0) {
        PERROR("Add memory hob failed, buffer too small");
        goto err_out;
    }

    if (add_vcpus_hob(hob_buf, vcpus) < 0) {
        PERROR("Add NR_VCPU hob failed, buffer too small");
        goto err_out;
    }

    if (add_pal_hob( hob_buf ) < 0) {
        PERROR("Add PAL hob failed, buffer too small");
        goto err_out;
    }

    if (add_nvram_hob( hob_buf, nvram_addr ) < 0) {
        PERROR("Add nvram hob failed, buffer too small");
        goto err_out;
    }

    return 0;

err_out:
    return -1;
}

static int
load_hob(int xc_handle, uint32_t dom, void *hob_buf)
{
    // hob_buf should be page aligned
    int hob_size;
    int nr_pages;

    hob_size = get_hob_size(hob_buf);
    if (hob_size < 0) {
        PERROR("Invalid hob data");
        return -1;
    }

    if (hob_size > GFW_HOB_SIZE) {
        PERROR("No enough memory for hob data");
        return -1;
    }

    nr_pages = (hob_size + PAGE_SIZE -1) >> PAGE_SHIFT;

    return xc_ia64_copy_to_domain_pages(xc_handle, dom, hob_buf,
                                        GFW_HOB_START >> PAGE_SHIFT, nr_pages);
}

#define MIN(x, y) (((x) < (y)) ? (x) : (y))
static int
add_mem_hob(void* hob_buf, unsigned long dom_mem_size)
{
    hob_mem_t memhob;

    // less than 3G accounting VGA RAM hole
    memhob.start = 0;
    if (dom_mem_size < VGA_IO_START)
        memhob.size = dom_mem_size;
    else
        memhob.size = MIN(dom_mem_size + VGA_IO_SIZE, 0xC0000000);

    if (hob_add(hob_buf, HOB_TYPE_MEM, &memhob, sizeof(memhob)) < 0)
        return -1;

    if (dom_mem_size > 0xC0000000) {
        // 4G ~ 4G+remain
        memhob.start = 0x100000000; //4G
        memhob.size = dom_mem_size + VGA_IO_SIZE - 0xC0000000;
        if (hob_add(hob_buf, HOB_TYPE_MEM, &memhob, sizeof(memhob)) < 0)
            return -1;
    }
    return 0;
}

static int 
add_vcpus_hob(void* hob_buf, unsigned long vcpus)
{
    return hob_add(hob_buf, HOB_TYPE_NR_VCPU, &vcpus, sizeof(vcpus));
}

static int
add_nvram_hob(void *hob_buf, unsigned long nvram_addr)
{
    return hob_add(hob_buf, HOB_TYPE_NVRAM, &nvram_addr, sizeof(nvram_addr));
}

static const unsigned char config_pal_bus_get_features_data[24] = {
    0, 0, 0, 32, 0, 0, 240, 189, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

static const unsigned char config_pal_cache_summary[16] = {
    3, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0
};

static const unsigned char config_pal_mem_attrib[8] = {
    241, 0, 0, 0, 0, 0, 0, 0
};

static const unsigned char config_pal_cache_info[152] = {
    3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    6, 4, 6, 7, 255, 1, 0, 1, 0, 64, 0, 0, 12, 12,
    49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 6, 7, 0, 1,
    0, 1, 0, 64, 0, 0, 12, 12, 49, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 6, 8, 7, 7, 255, 7, 0, 11, 0, 0, 16, 0,
    12, 17, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 8, 7,
    7, 7, 5, 9, 11, 0, 0, 4, 0, 12, 15, 49, 0, 254, 255,
    255, 255, 255, 255, 255, 255, 2, 8, 7, 7, 7, 5, 9,
    11, 0, 0, 4, 0, 12, 15, 49, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 3, 12, 7, 7, 7, 14, 1, 3, 0, 0, 192, 0, 12, 20, 49, 0
};

static const unsigned char config_pal_cache_prot_info[200] = {
    3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    45, 0, 16, 8, 0, 76, 12, 64, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    8, 0, 16, 4, 0, 76, 44, 68, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32,
    0, 16, 8, 0, 81, 44, 72, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0,
    112, 12, 0, 79, 124, 76, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 254, 255, 255, 255, 255, 255, 255, 255,
    32, 0, 112, 12, 0, 79, 124, 76, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 0, 160,
    12, 0, 84, 124, 76, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0
};

static const unsigned char config_pal_debug_info[16] = {
    2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0
};

static const unsigned char config_pal_fixed_addr[8] = {
    0, 0, 0, 0, 0, 0, 0, 0
};

static const unsigned char config_pal_freq_base[8] = {
    109, 219, 182, 13, 0, 0, 0, 0
};

static const unsigned char config_pal_freq_ratios[24] = {
    11, 1, 0, 0, 77, 7, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 4,
    0, 0, 0, 7, 0, 0, 0
};

static const unsigned char config_pal_halt_info[64] = {
    0, 0, 0, 0, 0, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

static const unsigned char config_pal_perf_mon_info[136] = {
    12, 47, 18, 8, 0, 0, 0, 0, 241, 255, 0, 0, 255, 7, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 241, 255, 0, 0, 223, 0, 255, 255,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 240, 255, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 240, 255, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0
};

static const unsigned char config_pal_proc_get_features[104] = {
    3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 64, 6, 64, 49, 0, 0, 0, 0, 64, 6, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0,
    231, 0, 0, 0, 0, 0, 0, 0, 228, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 17, 0, 0, 0, 0, 0, 0, 0,
    63, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0
};

static const unsigned char config_pal_ptce_info[24] = {
    0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0
};

static const unsigned char config_pal_register_info[64] = {
    255, 0, 47, 127, 17, 17, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
    255, 208, 128, 238, 238, 0, 0, 248, 255, 255, 255, 255, 255, 0, 0, 7, 3,
    251, 3, 0, 0, 0, 0, 255, 7, 3, 0, 0, 0, 0, 0, 248, 252, 4,
    252, 255, 255, 255, 255, 2, 248, 252, 255, 255, 255, 255, 255
};

static const unsigned char config_pal_rse_info[16] = {
    96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

static const unsigned char config_pal_test_info[48] = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

static const unsigned char config_pal_vm_summary[16] = {
    101, 18, 15, 2, 7, 7, 4, 2, 59, 18, 0, 0, 0, 0, 0, 0
};

static const unsigned char config_pal_vm_info[104] = {
    2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    32, 32, 0, 0, 0, 0, 0, 0, 112, 85, 21, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 1, 32, 32, 0, 0, 0, 0, 0, 0, 112, 85,
    21, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 128, 128, 0,
    4, 0, 0, 0, 0, 112, 85, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 1, 128, 128, 0, 4, 0, 0, 0, 0, 112, 85, 0, 0, 0, 0, 0
};

static const unsigned char config_pal_vm_page_size[16] = {
    0, 112, 85, 21, 0, 0, 0, 0, 0, 112, 85, 21, 0, 0, 0, 0
};

typedef struct{
    hob_type_t type;
    void* data;
    unsigned long size;
} hob_batch_t;

static const hob_batch_t hob_batch[]={
    {   HOB_TYPE_PAL_BUS_GET_FEATURES_DATA,
        &config_pal_bus_get_features_data,
        sizeof(config_pal_bus_get_features_data)
    },
    {   HOB_TYPE_PAL_CACHE_SUMMARY,
        &config_pal_cache_summary,
        sizeof(config_pal_cache_summary)
    },
    {   HOB_TYPE_PAL_MEM_ATTRIB,
        &config_pal_mem_attrib,
        sizeof(config_pal_mem_attrib)
    },
    {   HOB_TYPE_PAL_CACHE_INFO,
        &config_pal_cache_info,
        sizeof(config_pal_cache_info)
    },
    {   HOB_TYPE_PAL_CACHE_PROT_INFO,
        &config_pal_cache_prot_info,
        sizeof(config_pal_cache_prot_info)
    },
    {   HOB_TYPE_PAL_DEBUG_INFO,
        &config_pal_debug_info,
        sizeof(config_pal_debug_info)
    },
    {   HOB_TYPE_PAL_FIXED_ADDR,
        &config_pal_fixed_addr,
        sizeof(config_pal_fixed_addr)
    },
    {   HOB_TYPE_PAL_FREQ_BASE,
        &config_pal_freq_base,
        sizeof(config_pal_freq_base)
    },
    {   HOB_TYPE_PAL_FREQ_RATIOS,
        &config_pal_freq_ratios,
        sizeof(config_pal_freq_ratios)
    },
    {   HOB_TYPE_PAL_HALT_INFO,
        &config_pal_halt_info,
        sizeof(config_pal_halt_info)
    },
    {   HOB_TYPE_PAL_PERF_MON_INFO,
        &config_pal_perf_mon_info,
        sizeof(config_pal_perf_mon_info)
    },
    {   HOB_TYPE_PAL_PROC_GET_FEATURES,
        &config_pal_proc_get_features,
        sizeof(config_pal_proc_get_features)
    },
    {   HOB_TYPE_PAL_PTCE_INFO,
        &config_pal_ptce_info,
        sizeof(config_pal_ptce_info)
    },
    {   HOB_TYPE_PAL_REGISTER_INFO,
        &config_pal_register_info,
        sizeof(config_pal_register_info)
    },
    {   HOB_TYPE_PAL_RSE_INFO,
        &config_pal_rse_info,
        sizeof(config_pal_rse_info)
    },
    {   HOB_TYPE_PAL_TEST_INFO,
        &config_pal_test_info,
        sizeof(config_pal_test_info)
    },
    {   HOB_TYPE_PAL_VM_SUMMARY,
        &config_pal_vm_summary,
        sizeof(config_pal_vm_summary)
    },
    {   HOB_TYPE_PAL_VM_INFO,
        &config_pal_vm_info,
        sizeof(config_pal_vm_info)
    },
    {   HOB_TYPE_PAL_VM_PAGE_SIZE,
        &config_pal_vm_page_size,
        sizeof(config_pal_vm_page_size)
    },
};

static int
add_pal_hob(void* hob_buf)
{
    int i;
    for (i = 0; i < sizeof(hob_batch)/sizeof(hob_batch_t); i++) {
        if (hob_add(hob_buf, hob_batch[i].type, hob_batch[i].data,
                    hob_batch[i].size) < 0)
            return -1;
    }
    return 0;
}

// The most significant bit of nvram file descriptor:
// 1: valid; 0: invalid
#define VALIDATE_NVRAM_FD(x) ((1UL<<(sizeof(x)*8 - 1)) | x)
#define IS_VALID_NVRAM_FD(x) ((uint64_t)x >> (sizeof(x)*8 - 1))
static uint64_t 
nvram_init(const char *nvram_path)
{
    uint64_t fd = 0;
    fd = open(nvram_path, O_CREAT|O_RDWR, 0644);

    if ( fd < 0 )
    {
        PERROR("Nvram open failed at %s. Guest will boot without"
               " nvram support!\n", nvram_path);	
        return -1;
    }

    return VALIDATE_NVRAM_FD(fd);
}

static int 
copy_from_nvram_to_GFW(int xc_handle, uint32_t dom, int nvram_fd)
{
    unsigned int nr_pages = NVRAM_SIZE >> PAGE_SHIFT;
    struct stat file_stat;
    char buf[NVRAM_SIZE] = {0};

    if ( fstat(nvram_fd, &file_stat) < 0 )
    {
        PERROR("Cannot get Nvram file info! Guest will boot without "
               "nvram support!\n");
        return -1;
    }

    if ( 0 == file_stat.st_size )
    {
        DPRINTF("Nvram file create successful!\n");
        return 0;
    }

    if ( read(nvram_fd, buf, NVRAM_SIZE) != NVRAM_SIZE )
    {
        PERROR("Load nvram fail. guest will boot without"
               " nvram support!\n");
        return -1;
    }

    return  xc_ia64_copy_to_domain_pages(xc_handle, dom, buf,
                                         NVRAM_START >> PAGE_SHIFT, nr_pages);
}


/*
 *Check is the address where NVRAM data located valid
 */
static int is_valid_address(void *addr)
{
    struct nvram_save_addr *p = (struct nvram_save_addr *)addr;	

    if ( p->signature == NVRAM_VALID_SIG )
        return 1;
    else {
        PERROR("Invalid nvram signature. Nvram save failed!\n");
        return 0;
    }
}

/*
 * GFW use 4k page. when doing foreign map, we should 16k align
 * the address and map one more page to guarantee all 64k nvram data 
 * can be got.
 */
static int
copy_from_GFW_to_nvram(int xc_handle, uint32_t dom, int nvram_fd)
{
    xen_pfn_t *pfn_list = NULL;
    char *tmp_ptr = NULL;
    unsigned int nr_pages = 0;
    uint64_t addr_from_GFW_4k_align = 0;
    uint32_t offset = 0;
    uint64_t nvram_base_addr = 0;
    char buf[NVRAM_SIZE] = {0};
    int i;

    // map one more page 
    nr_pages = (NVRAM_SIZE + PAGE_SIZE) >> PAGE_SHIFT;
    pfn_list = (xen_pfn_t *)malloc(sizeof(xen_pfn_t) * nr_pages);
    if ( NULL == pfn_list )
    {
        PERROR("Cannot allocate memory for nvram save!\n");
        close(nvram_fd);
        return -1;
    }

    /* 
     * GFW allocate memory dynamicly to save nvram data
     * and save address of the dynamic memory at NVRAM_START. 
     * To save nvram data to file, we must get the dynamic
     * memory address first.
     */
    pfn_list[0] = NVRAM_START >> PAGE_SHIFT;
    tmp_ptr = (char *)xc_map_foreign_range(xc_handle, dom, PAGE_SIZE,
                                           PROT_READ | PROT_WRITE, pfn_list[0]);

    if ( NULL == tmp_ptr )
    {
        PERROR("Cannot get nvram data from GFW!\n");
        free(pfn_list);
        close(nvram_fd);
        return -1;
    }

    /* Check is NVRAM data vaild */
    if ( !is_valid_address(tmp_ptr) )
    {
        free(pfn_list);
        munmap(tmp_ptr, PAGE_SIZE);
        close(nvram_fd);
        return -1;
    }

    addr_from_GFW_4k_align = ((struct nvram_save_addr *)tmp_ptr)->addr;
    munmap(tmp_ptr, PAGE_SIZE);

    // align address to 16k
    offset = addr_from_GFW_4k_align % ( 16 * MEM_K );
    addr_from_GFW_4k_align = addr_from_GFW_4k_align - offset;
    for ( i=0; i<nr_pages; i++ )
        pfn_list[i] = (addr_from_GFW_4k_align >> PAGE_SHIFT) + i;

    tmp_ptr = (char *)xc_map_foreign_pages(xc_handle, dom,
                                           PROT_READ | PROT_WRITE,
                                           pfn_list, nr_pages);
    if ( NULL == tmp_ptr )
    {
        PERROR("Cannot get nvram data from GFW!\n");
        free(pfn_list);
        close(nvram_fd);
        return -1;
    }

    // calculate nvram data base addrees
    nvram_base_addr = (uint64_t)(tmp_ptr + offset);

    memcpy(buf, (void *)nvram_base_addr, NVRAM_SIZE);
    free(pfn_list);
    munmap(tmp_ptr, NVRAM_SIZE + PAGE_SIZE);

    lseek(nvram_fd, 0, SEEK_SET);
    if ( write(nvram_fd, buf, NVRAM_SIZE) != NVRAM_SIZE )
    {
        PERROR("Save to nvram fail!\n");
        return -1;
    }

    close(nvram_fd);

    DPRINTF("Nvram save successful!\n");

    return 0;
}

int xc_ia64_save_to_nvram(int xc_handle, uint32_t dom) 
{
    xc_dominfo_t info;
    uint64_t nvram_fd = 0;

    if ( xc_domain_getinfo(xc_handle, dom, 1, &info) != 1 )
    {
        PERROR("Could not get info for domain");
        return -1;
    }

    if ( !info.hvm )
        return 0;

    xc_get_hvm_param(xc_handle, dom, HVM_PARAM_NVRAM_FD, &nvram_fd);

    if ( !IS_VALID_NVRAM_FD(nvram_fd) )
        PERROR("Nvram not initialized. Nvram save failed!\n");
    else
        copy_from_GFW_to_nvram(xc_handle, dom, (int)nvram_fd);	

    // although save to nvram maybe fail, we don't return any error number
    // to Xend. This is quite logical because damage of NVRAM on native would 
    // not block OS's executive path. Return error number will cause an
    // exception of Xend and block XenU when it destroy.
    return 0;
}

#define NVRAM_DIR         "/var/lib/xen/nvram/"
#define NVRAM_FILE_PREFIX "nvram_"

int xc_ia64_nvram_init(int xc_handle, char *dom_name, uint32_t dom)
{
    uint64_t nvram_fd;
    char nvram_path[PATH_MAX] = NVRAM_DIR;

    if ( access(nvram_path, R_OK|W_OK|X_OK) == -1 ) {
        if ( errno != ENOENT )
        {
            PERROR("Error stat'ing NVRAM dir %s.", nvram_path);
            return -1;
        }
        if ( mkdir(nvram_path, 0755) == -1 )
        {
            PERROR("Unable to create NVRAM store directory %s.", nvram_path);
            return -1;
        }
    }

    if ( access(nvram_path, R_OK|W_OK|X_OK) == -1 ) {
        errno = EACCES;
        PERROR("No RWX permission to NVRAM store directory %s.", nvram_path);
        return -1;
    }

    if ( strlen(nvram_path) + strlen(NVRAM_FILE_PREFIX) +
         strlen(dom_name) + 1 > sizeof(nvram_path) )
    {
        PERROR("Nvram file path is too long!\n");
        return -1;
    }
    strcat(nvram_path, NVRAM_FILE_PREFIX);
    strcat(nvram_path, dom_name);

    nvram_fd = nvram_init(nvram_path);
    if ( nvram_fd == (uint64_t)(-1) )
    {
        xc_set_hvm_param(xc_handle, dom, HVM_PARAM_NVRAM_FD, 0);
        return -1;
    }

    xc_set_hvm_param(xc_handle, dom, HVM_PARAM_NVRAM_FD, nvram_fd);
    return 0; 
}

#define GFW_PAGES (GFW_SIZE >> PAGE_SHIFT)
#define VGA_START_PAGE (VGA_IO_START >> PAGE_SHIFT)
#define VGA_END_PAGE ((VGA_IO_START + VGA_IO_SIZE) >> PAGE_SHIFT)

static void
xc_ia64_setup_md(efi_memory_desc_t *md,
                 unsigned long start, unsigned long end)
{
    md->type = EFI_CONVENTIONAL_MEMORY;
    md->pad = 0;
    md->phys_addr = start;
    md->virt_addr = 0;
    md->num_pages = (end - start) >> EFI_PAGE_SHIFT;
    md->attribute = EFI_MEMORY_WB;
}

static inline unsigned long 
min(unsigned long lhs, unsigned long rhs)
{
    return (lhs < rhs)? lhs: rhs;
}

static int
xc_ia64_setup_memmap_info(int xc_handle, uint32_t dom,
                          unsigned long dom_memsize, /* in bytes */
                          unsigned long *pfns_special_pages, 
                          unsigned long nr_special_pages,
                          unsigned long memmap_info_pfn,
                          unsigned long memmap_info_num_pages)
{
    xen_ia64_memmap_info_t* memmap_info;
    efi_memory_desc_t *md;
    uint64_t nr_mds;
    
    memmap_info = xc_map_foreign_range(xc_handle, dom,
                                       PAGE_SIZE * memmap_info_num_pages,
                                       PROT_READ | PROT_WRITE,
                                       memmap_info_pfn);
    if (memmap_info == NULL) {
        PERROR("Could not map memmmap_info page.\n");
        return -1;
    }
    memset(memmap_info, 0, PAGE_SIZE * memmap_info_num_pages);

    /*
     * [0, VGA_IO_START = 0xA0000)
     * [VGA_IO_START + VGA_IO_SIZE = 0xC0000, MMIO_START = 3GB)
     * [IO_PAGE_START (> 3GB), IO_PAGE_START + IO_PAGE_SIZE)
     * [STORE_PAGE_START, STORE_PAGE_START + STORE_PAGE_SIZE)
     * [BUFFER_IO_PAGE_START, BUFFER_IO_PAGE_START + BUFFER_IO_PAGE_SIZE)
     * [BUFFER_PIO_PAGE_START, BUFFER_PIO_PAGE_START + BUFFER_PIO_PAGE_SIZE)
     * [memmap_info_pfn << PAGE_SHIFT,
     *                          (memmap_info_pfn << PAGE_SHIFT) + PAGE_SIZE)
     * [GFW_START=4GB - GFW_SIZE, GFW_START + GFW_SIZE = 4GB)
     * [4GB, ...)
     */ 
    md = (efi_memory_desc_t*)&memmap_info->memdesc;
    xc_ia64_setup_md(md, 0, min(VGA_IO_START, dom_memsize));
    md++;

    if (dom_memsize > VGA_IO_START) {
        xc_ia64_setup_md(md, VGA_IO_START + VGA_IO_SIZE,
                         min(MMIO_START, dom_memsize + VGA_IO_SIZE));
        md++;
    }
    xc_ia64_setup_md(md, IO_PAGE_START, IO_PAGE_START + IO_PAGE_SIZE);
    md++;
    xc_ia64_setup_md(md, STORE_PAGE_START, STORE_PAGE_START + STORE_PAGE_SIZE);
    md++;
    xc_ia64_setup_md(md, BUFFER_IO_PAGE_START,
                     BUFFER_IO_PAGE_START + BUFFER_IO_PAGE_SIZE);
    md++;
    xc_ia64_setup_md(md, BUFFER_PIO_PAGE_START,
                     BUFFER_PIO_PAGE_START + BUFFER_PIO_PAGE_SIZE);
    md++;
    xc_ia64_setup_md(md, memmap_info_pfn << PAGE_SHIFT,
                     (memmap_info_pfn << PAGE_SHIFT) +
                     PAGE_SIZE * memmap_info_num_pages);
    md++;
    xc_ia64_setup_md(md, GFW_START, GFW_START + GFW_SIZE);
    md++;
    if (dom_memsize + VGA_IO_SIZE > MMIO_START) {
        xc_ia64_setup_md(md, 4 * MEM_G, dom_memsize + VGA_IO_SIZE + (1 * MEM_G));
        md++;
    }
    nr_mds = md - (efi_memory_desc_t*)&memmap_info->memdesc;
    
    assert(nr_mds <=
           (PAGE_SIZE * memmap_info_num_pages -
            offsetof(typeof(*memmap_info), memdesc))/sizeof(*md));
    memmap_info->efi_memmap_size = nr_mds * sizeof(*md);
    memmap_info->efi_memdesc_size = sizeof(*md);
    memmap_info->efi_memdesc_version = EFI_MEMORY_DESCRIPTOR_VERSION;

    munmap(memmap_info, PAGE_SIZE * memmap_info_num_pages);
    return 0;
}

/* setup shared_info page */
static int
xc_ia64_setup_shared_info(int xc_handle, uint32_t dom,
                          unsigned long shared_info_pfn,
                          unsigned long memmap_info_pfn,
                          unsigned long memmap_info_num_pages)
{
    shared_info_t *shared_info;

    shared_info = xc_map_foreign_range(xc_handle, dom, PAGE_SIZE,
                                       PROT_READ | PROT_WRITE,
                                       shared_info_pfn);
    if (shared_info == NULL) {
        PERROR("Could not map shared_info");
        return -1;
    }
    memset(shared_info, 0, sizeof(*shared_info));
    shared_info->arch.memmap_info_num_pages = memmap_info_num_pages;
    shared_info->arch.memmap_info_pfn = memmap_info_pfn;
    munmap(shared_info, PAGE_SIZE);
    return 0;
}

/*
 * In this function, we will allocate memory and build P2M/M2P table for VTI
 * guest.  Frist, a pfn list will be initialized discontiguous, normal memory
 * begins with 0, GFW memory and other five pages at their place defined in
 * xen/include/public/arch-ia64.h xc_domain_memory_populate_physmap() called
 * five times, to set parameter 'extent_order' to different value, this is
 * convenient to allocate discontiguous memory with different size.
 */
static int
setup_guest(int xc_handle, uint32_t dom, unsigned long memsize,
            char *image, unsigned long image_size)
{
    xen_pfn_t *pfn_list;
    unsigned long dom_memsize = memsize << 20;
    unsigned long nr_pages = memsize << (20 - PAGE_SHIFT);
    unsigned long vcpus;
    unsigned long nr_special_pages;
    unsigned long memmap_info_pfn;
    unsigned long memmap_info_num_pages;
    unsigned long nvram_start = NVRAM_START, nvram_fd = 0; 
    int rc;
    unsigned long i;
    unsigned long pfn;
    const struct hvm_special_page {
        int             param;
        xen_pfn_t       pfn;
    } special_pages[] = {
        // pfn-sorted array
        { HVM_PARAM_IOREQ_PFN,          IO_PAGE_START         >> PAGE_SHIFT},
        { HVM_PARAM_STORE_PFN,          STORE_PAGE_START      >> PAGE_SHIFT},
        { HVM_PARAM_BUFIOREQ_PFN,       BUFFER_IO_PAGE_START  >> PAGE_SHIFT}, 
        { HVM_PARAM_BUFPIOREQ_PFN,      BUFFER_PIO_PAGE_START >> PAGE_SHIFT},
    };
    DECLARE_DOMCTL;


    if ((image_size > 12 * MEM_M) || (image_size & (PAGE_SIZE - 1))) {
        PERROR("Guest firmware size is incorrect [%ld]?", image_size);
        return -1;
    }

    pfn_list = malloc(nr_pages * sizeof(xen_pfn_t));
    if (pfn_list == NULL) {
        PERROR("Could not allocate memory.\n");
        return -1;
    }

    //
    // Populate
    // [0, VGA_IO_START) (VGA_IO_SIZE hole)
    // [VGA_IO_START + VGA_IO_SIZE, MMIO_START) (1GB hole)
    // [4GB, end)
    //                     
    i = 0;
    for (pfn = 0;
         pfn < MIN((dom_memsize >> PAGE_SHIFT), VGA_START_PAGE);
         pfn++)
        pfn_list[i++] = pfn;
    for (pfn = VGA_END_PAGE;
         pfn < (MIN(dom_memsize + VGA_IO_SIZE, MMIO_START) >> PAGE_SHIFT);
         pfn++)
        pfn_list[i++] = pfn;
    for (pfn = ((4 * MEM_G) >> PAGE_SHIFT); 
         pfn < ((dom_memsize + VGA_IO_SIZE + 1 * MEM_G) >> PAGE_SHIFT);
         pfn++)
        pfn_list[i++] = pfn;

    rc = xc_domain_memory_populate_physmap(xc_handle, dom, nr_pages, 0, 0,
                                           &pfn_list[0]);
    if (rc != 0) {
        PERROR("Could not allocate normal memory for Vti guest.\n");
        goto error_out;
    }

    // We allocate additional pfn for GFW and other five pages, so
    // the pfn_list is not contiguous.  Due to this we must support
    // old interface xc_ia64_get_pfn_list().
    for (i = 0; i < GFW_PAGES; i++) 
        pfn_list[i] = (GFW_START >> PAGE_SHIFT) + i;

    rc = xc_domain_memory_populate_physmap(xc_handle, dom, GFW_PAGES,
                                           0, 0, &pfn_list[0]);
    if (rc != 0) {
        PERROR("Could not allocate GFW memory for Vti guest.\n");
        goto error_out;
    }

    for (i = 0; i < sizeof(special_pages) / sizeof(special_pages[0]); i++)
        pfn_list[i] = special_pages[i].pfn;

    nr_special_pages = i;
    memmap_info_pfn = pfn_list[nr_special_pages - 1] + 1;
    memmap_info_num_pages = 1;
    pfn_list[nr_special_pages] = memmap_info_pfn;
    nr_special_pages++;

    rc = xc_domain_memory_populate_physmap(xc_handle, dom, nr_special_pages,
                                           0, 0, &pfn_list[0]);
    if (rc != 0) {
        PERROR("Could not allocate IO page or store page or buffer io page.\n");
        goto error_out;
    }

    domctl.u.arch_setup.flags = 0;
    domctl.u.arch_setup.bp = 0;
    domctl.u.arch_setup.maxmem = GFW_START + GFW_SIZE;
    if (dom_memsize + VGA_IO_SIZE > MMIO_START)
        domctl.u.arch_setup.maxmem = dom_memsize + VGA_IO_SIZE + 1 * MEM_G;
    domctl.cmd = XEN_DOMCTL_arch_setup;
    domctl.domain = (domid_t)dom;
    if (xc_domctl(xc_handle, &domctl))
        goto error_out;

    // Load guest firmware 
    if (xc_ia64_copy_to_domain_pages(xc_handle, dom, image,
                            (GFW_START + GFW_SIZE - image_size) >> PAGE_SHIFT,
                            image_size >> PAGE_SHIFT)) {
        PERROR("Could not load guest firmware into domain");
        goto error_out;
    }

    domctl.cmd = XEN_DOMCTL_getdomaininfo;
    domctl.domain = (domid_t)dom;
    if (xc_domctl(xc_handle, &domctl) < 0) {
        PERROR("Could not get info on domain");
        goto error_out;
    }

    if (xc_ia64_setup_memmap_info(xc_handle, dom, dom_memsize,
                                  pfn_list, nr_special_pages,
                                  memmap_info_pfn, memmap_info_num_pages)) {
        PERROR("Could not build memmap info\n");
        goto error_out;
    }
    if (xc_ia64_setup_shared_info(xc_handle, dom,
                                  domctl.u.getdomaininfo.shared_info_frame,
                                  memmap_info_pfn, memmap_info_num_pages)) {
        PERROR("Could not setup shared_info\n");
        goto error_out;
    }

    xc_get_hvm_param(xc_handle, dom, HVM_PARAM_NVRAM_FD, &nvram_fd);
    if ( !IS_VALID_NVRAM_FD(nvram_fd) )
        nvram_start = 0;
    else if ( copy_from_nvram_to_GFW(xc_handle, dom, (int)nvram_fd ) == -1 ) {
        nvram_start = 0;
        close(nvram_fd);
    }

    vcpus = domctl.u.getdomaininfo.max_vcpu_id + 1;

    // Hand-off state passed to guest firmware 
    if (xc_ia64_build_hob(xc_handle, dom, dom_memsize, vcpus, nvram_start) < 0) {
        PERROR("Could not build hob\n");
        goto error_out;
    }

    // zero clear all special pages
    for (i = 0; i < sizeof(special_pages) / sizeof(special_pages[0]); i++) {
        xc_set_hvm_param(xc_handle, dom,
                         special_pages[i].param, special_pages[i].pfn);
        if (xc_clear_domain_page(xc_handle, dom, special_pages[i].pfn))
            goto error_out;
    }

    free(pfn_list);
    return 0;

error_out:
    return -1;
}

int
xc_hvm_build(int xc_handle, uint32_t domid, int memsize, const char *image_name)
{
    vcpu_guest_context_any_t st_ctxt_any;
    vcpu_guest_context_t *ctxt = &st_ctxt_any.c;
    char *image = NULL;
    unsigned long image_size;
    unsigned long nr_pages;

    nr_pages = xc_get_max_pages(xc_handle, domid);
    if (nr_pages < 0) {
        PERROR("Could not find total pages for domain");
        goto error_out;
    }

    image = xc_read_image(image_name, &image_size);
    if (image == NULL) {
        PERROR("Could not read guest firmware image %s", image_name);
        goto error_out;
    }

    image_size = (image_size + PAGE_SIZE - 1) & PAGE_MASK;

    if (setup_guest(xc_handle, domid, (unsigned long)memsize, image,
                    image_size) < 0) {
        ERROR("Error constructing guest OS");
        goto error_out;
    }

    free(image);

    memset(&st_ctxt_any, 0, sizeof(st_ctxt_any));
    ctxt->regs.ip = 0x80000000ffffffb0UL;
    ctxt->regs.ar.fpsr = xc_ia64_fpsr_default();
    ctxt->regs.cr.itir = 14 << 2;
    ctxt->regs.psr = IA64_PSR_AC | IA64_PSR_BN;
    ctxt->regs.cr.dcr = 0;
    ctxt->regs.cr.pta = 15 << 2;
    return xc_vcpu_setcontext(xc_handle, domid, 0, &st_ctxt_any);

error_out:
    free(image);
    return -1;
}

/* xc_hvm_build_target_mem: 
 * Create a domain for a pre-ballooned virtualized Linux, using
 * files/filenames.  If target < memsize, domain is created with
 * memsize pages marked populate-on-demand, and with a PoD cache size
 * of target.  If target == memsize, pages are populated normally.
 */
int xc_hvm_build_target_mem(int xc_handle,
                            uint32_t domid,
                            int memsize,
                            int target,
                            const char *image_name)
{
    /* XXX:PoD isn't supported yet */
    return xc_hvm_build(xc_handle, domid, target, image_name);
}

/*
 * From asm/pgtable.h
 */
#define _PAGE_P_BIT     0
#define _PAGE_A_BIT     5
#define _PAGE_D_BIT     6

#define _PAGE_P         (1 << _PAGE_P_BIT)      /* page present bit */
#define _PAGE_A         (1 << _PAGE_A_BIT)      /* page accessed bit */
#define _PAGE_D         (1 << _PAGE_D_BIT)      /* page dirty bit */

#define _PAGE_MA_WB     (0x0 <<  2)     /* write back memory attribute */
#define _PAGE_MA_UC     (0x4 <<  2)     /* uncacheable memory attribute */
#define _PAGE_AR_RW     (2 <<  9)       /* read & write */

int
xc_ia64_set_os_type(int xc_handle, char *guest_os_type, uint32_t dom)
{
    DECLARE_DOMCTL;

    domctl.cmd = XEN_DOMCTL_set_opt_feature;
    domctl.domain = (domid_t)dom;

    if (!guest_os_type || !strlen(guest_os_type) ||
        !strcmp("default", guest_os_type)) {

        /* Nothing */
        return 0;

    } else if (!strcmp("windows", guest_os_type)) {
        DPRINTF("Enabling Windows guest OS optimizations\n");

        /* Windows identity maps regions 4 & 5 */
        domctl.u.set_opt_feature.optf.cmd = XEN_IA64_OPTF_IDENT_MAP_REG4;
        domctl.u.set_opt_feature.optf.on = XEN_IA64_OPTF_ON;
        domctl.u.set_opt_feature.optf.pgprot = (_PAGE_P | _PAGE_A | _PAGE_D |
                                                _PAGE_MA_WB | _PAGE_AR_RW);
        domctl.u.set_opt_feature.optf.key = 0;
        if (xc_domctl(xc_handle, &domctl))
            PERROR("Failed to set region 4 identity mapping for Windows "
                   "guest OS type.\n");

        domctl.u.set_opt_feature.optf.cmd = XEN_IA64_OPTF_IDENT_MAP_REG5;
        domctl.u.set_opt_feature.optf.on = XEN_IA64_OPTF_ON;
        domctl.u.set_opt_feature.optf.pgprot = (_PAGE_P | _PAGE_A | _PAGE_D |
                                                _PAGE_MA_UC | _PAGE_AR_RW);
        domctl.u.set_opt_feature.optf.key = 0;
        if (xc_domctl(xc_handle, &domctl))
            PERROR("Failed to set region 5 identity mapping for Windows "
                   "guest OS type.\n");
        return 0;

    } else if (!strcmp("linux", guest_os_type)) {
        DPRINTF("Enabling Linux guest OS optimizations\n");

        /* Linux identity maps regions 7 */
        domctl.u.set_opt_feature.optf.cmd = XEN_IA64_OPTF_IDENT_MAP_REG7;
        domctl.u.set_opt_feature.optf.on = XEN_IA64_OPTF_ON;
        domctl.u.set_opt_feature.optf.pgprot = (_PAGE_P | _PAGE_A | _PAGE_D |
                                                _PAGE_MA_WB | _PAGE_AR_RW);
        domctl.u.set_opt_feature.optf.key = 0;
        if (xc_domctl(xc_handle, &domctl))
            PERROR("Failed to set region 7 identity mapping for Linux "
                   "guest OS type.\n");
        return 0;
    }

    DPRINTF("Unknown guest_os_type (%s), using defaults\n", guest_os_type);

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
