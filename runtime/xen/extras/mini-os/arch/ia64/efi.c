/*
 * Done by Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
 * The code is partly taken from FreeBSD.
 *
 ***************************************************************************
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */


#include <mini-os/os.h>
#include <mini-os/efi.h>
#include <mini-os/page.h>
#include <mini-os/lib.h>
#include <mini-os/console.h>


/* The implementation is in fw.S. */
extern uint64_t
ia64_call_efi_func(uint64_t funcP,uint64_t a,uint64_t b,uint64_t c,uint64_t d);

int
efi_get_time(efi_time_t* tmP)
{
	memset(tmP, 0, sizeof(efi_time_t));
	if (ia64_call_efi_func((uint64_t)machineFwG.efi.getTimeF,
			       (uint64_t)tmP,
			       (uint64_t)NULL, 0, 0) != EFI_SUCCESS) {
		printk("efi.getTime() failed\n");
		return 0;
	}
	return 1;
}

/*
 * The function compares two efi_guid_t and returns 0 on equality, otherwise 1.
 */
static int
efi_guid_cmp(efi_guid_t* a_le, efi_guid_t* b)
{
	return memcmp(a_le, b, sizeof(efi_guid_t));
}

void
init_efi(void)
{
	efi_system_table_t* efiSysTableP;
	int mdcnt, i, numConvMem;
	efi_memory_descriptor_t *memdP, *mdP;
	efi_status_t status;
	char fwVendor[100] = "unknown";
	efi_char16_t* fwP;
	efi_runtime_services_t* rsP;

	efi_configuration_table_t* confP = (efi_configuration_table_t*)0;
	efi_guid_t sal = SAL_SYSTEM_TABLE_GUID;
	efi_guid_t acpi = ACPI_TABLE_GUID;
	efi_guid_t acpi20 = ACPI_20_TABLE_GUID;
	
	memset(&machineFwG, 0, sizeof(machineFwG));
	/* Read the efi_system_table.  */
	efiSysTableP = (efi_system_table_t*)__va(ia64BootParamG.efi_systab);
	machineFwG.efi.efiSysTableP = efiSysTableP;
	PRINT_BV("EfiSystemTable at: %p\n", efiSysTableP);
	fwP = (uint16_t*) __va(efiSysTableP->FirmwareVendor);
	if (fwP) {
		for (i = 0; i < (int)sizeof(fwVendor) - 1 && *fwP; ++i)
			fwVendor[i] = *fwP++;
		fwVendor[i] = '\0';
	}
	PRINT_BV("  EFI-FirmwareVendor        : %s\n", fwVendor);
	PRINT_BV("  EFI-FirmwareRevision      : %d\n",
		 efiSysTableP->FirmwareRevision);
	PRINT_BV("  EFI-SystemTable-Revision  : %d.%d\n",
		 efiSysTableP->Hdr.Revision >> 16,
		 efiSysTableP->Hdr.Revision & 0xffff);
	rsP = (efi_runtime_services_t*)
		__va(efiSysTableP->RuntimeServices);
	mdcnt = ia64BootParamG.efi_memmap_size /
		ia64BootParamG.efi_memdesc_size;
	memdP = (efi_memory_descriptor_t*) __va(ia64BootParamG.efi_memmap);

	PRINT_BV("EFI-Memorydescriptors: %d\n", mdcnt);

	for (i = numConvMem = 0, mdP = memdP; i < mdcnt; i++,
	     mdP = NextMemoryDescriptor(mdP, ia64BootParamG.efi_memdesc_size)) {
		/* Relocate runtime memory segments for firmware. */
		PRINT_BV("  %d. Type: %x  Attributes: 0x%lx\n",
			 i, mdP->Type, mdP->Attribute);
		PRINT_BV("     PhysStart: 0x%lx  NumPages: 0x%lx\n",
			 mdP->PhysicalStart, mdP->NumberOfPages);
		switch (mdP->Type) {
			case EfiRuntimeServicesData:
				PRINT_BV("     -> EfiRuntimeServicesData\n");
				break;
			case EfiACPIReclaimMemory:
				PRINT_BV("     -> EfiACPIReclaimMemory\n");
				break;
			case EfiACPIMemoryNVS:
				PRINT_BV("     -> EfiACPIMemoryNVS\n");
				break;
			case EfiConventionalMemory:
				PRINT_BV("     -> EfiConventionalMemory\n");
				PRINT_BV("        start: 0x%lx end: 0x%lx\n",
					mdP->PhysicalStart,
					mdP->PhysicalStart +
					mdP->NumberOfPages * EFI_PAGE_SIZE);
				if (numConvMem) {
					printk("     Currently only one efi "
						"memory chunk supported !!!\n");
					break;
				}
				machineFwG.mach_mem_start = mdP->PhysicalStart;
				machineFwG.mach_mem_size =
					mdP->NumberOfPages * EFI_PAGE_SIZE;
				numConvMem++;
				break;
			case EfiMemoryMappedIOPortSpace:
				PRINT_BV("     -> EfiMemMappedIOPortSpace\n");
				break;
			case EfiPalCode:
                       		machineFwG.ia64_pal_base =
					__va(mdP->PhysicalStart);
				PRINT_BV("     -> EfiPalCode\n"
					 "        start : %p\n",
					 machineFwG.ia64_pal_base);
				break;
		}
		/* I have to setup the VirtualStart address of every
		 * RUNTIME-area in preparing the later call of
		 * SetVirtualAddressMap() therewidth the efi stuff uses
		 * virtual addressing and the efi runtime functions
		 * may be called directly.
		 */
		if (mdP->Attribute & EFI_MEMORY_RUNTIME) {
			if (mdP->Attribute & EFI_MEMORY_WB)
				mdP->VirtualStart = __va(mdP->PhysicalStart);
			else {
				if (mdP->Attribute & EFI_MEMORY_UC)
					printk("efi_init: RuntimeMemory with "
						"UC attribute !!!!!!\n");
					/*
					mdP->VirtualStart =
					IA64_PHYS_TO_RR6(mdP->PhysicalStart);
					*/
			}
		}
	}
	/* Now switch efi runtime stuff to virtual addressing. */
	status = ia64_call_efi_physical(
			(void*)__va((uint64_t)rsP->SetVirtualAddressMap),
			ia64BootParamG.efi_memmap_size,
			ia64BootParamG.efi_memdesc_size,
			ia64BootParamG.efi_memdesc_version,
			ia64BootParamG.efi_memmap);
	status = EFI_SUCCESS;
	if (status != EFI_SUCCESS) {
		printk("warning: unable to switch EFI into virtual "
		       "(status=%lu)\n", status);
		return;
	}
	/* Getting efi function pointer for getEfiTime. */
	machineFwG.efi.getTimeF =
		(efi_get_time_t)__va((uint64_t)rsP->GetTime);
	/* Getting efi function pointer for resetSystem. */
	machineFwG.efi.resetSystemF =
		(efi_reset_system_t)__va((uint64_t)rsP->ResetSystem);

	/* Scanning the Configuration table of the EfiSystemTable. */
	PRINT_BV("NumberOfConfigTableEntries: %ld\n",
		 efiSysTableP->NumberOfTableEntries);

	confP = (efi_configuration_table_t*)
			__va(efiSysTableP->ConfigurationTable);
	for (i = 0; i < efiSysTableP->NumberOfTableEntries; i++) {
		if (!efi_guid_cmp(&confP[i].VendorGuid, &sal)) {
			machineFwG.ia64_sal_tableP = (sal_system_table_t*)
				__va((uint64_t) confP[i].VendorTable);
			PRINT_BV("  Found SalSystemTable at: 0x%lx\n",
				 (uint64_t) machineFwG.ia64_sal_tableP);
			continue;
		}
		if (!efi_guid_cmp(&confP[i].VendorGuid, &acpi)) {
			machineFwG.ia64_efi_acpi_table =
				__va((uint64_t) confP[i].VendorTable);
			PRINT_BV("  Found AcpiTable at:      0x%lx\n",
				 (uint64_t) machineFwG.ia64_efi_acpi_table);
			continue;
		}
		if (!efi_guid_cmp(&confP[i].VendorGuid, &acpi20)) {
			machineFwG.ia64_efi_acpi20_table =
				__va((uint64_t) confP[i].VendorTable);
			PRINT_BV("  Found Acpi20Table at:    0x%lx\n",
				 (uint64_t) machineFwG.ia64_efi_acpi20_table);
			continue;
		}
	}
}
