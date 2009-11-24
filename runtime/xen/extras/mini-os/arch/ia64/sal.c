/*
 * Done by Dietmar Hahn <dietmar.hahn@fujitsu-siemens.com>
 * Mostly taken from FreeBSD.
 *
 ****************************************************************************
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
#include <mini-os/lib.h>
#include <mini-os/console.h>
#include <mini-os/page.h>


static struct ia64_fdesc sal_fdesc;
uint64_t ia64_pal_entry;	/* PAL_PROC entrypoint */


struct ia64_sal_result
ia64_sal_call(uint64_t a1, uint64_t a2, uint64_t a3, uint64_t a4,
	      uint64_t a5, uint64_t a6, uint64_t a7, uint64_t a8)
{
	return ia64_sal_entry(a1, a2, a3, a4, a5, a6, a7, a8);
}

static struct ia64_sal_result
fake_sal(uint64_t a1, uint64_t a2, uint64_t a3, uint64_t a4,
	 uint64_t a5, uint64_t a6, uint64_t a7, uint64_t a8)
{
	struct ia64_sal_result res;
	res.sal_status = -3;
	res.sal_result[0] = 0;
	res.sal_result[1] = 0;
	res.sal_result[2] = 0;
	return res;
}

/*
 * Currently only the SAL_DESC_ENTRYPOINT is checked to get
 * the entry points the pal and sal functions.
 */
void
ia64_sal_init(struct sal_system_table *saltab)
{
	static int sizes[6] = { 48, 32, 16, 32, 16, 16 };
	uint8_t *p;
	int i;

	PRINT_BV("Reading SALtable:\n");
	ia64_sal_entry = fake_sal;

	if (memcmp((void*)(uint64_t)(saltab->sal_signature), SAL_SIGNATURE, 4))
	{
		printk("Bad signature for SAL System Table\n");
		return;
	}
	p = (uint8_t *) (saltab + 1);
	for (i = 0; i < saltab->sal_entry_count; i++) {
		switch (*p) {
		case SAL_DESC_ENTRYPOINT:		// 0
		{
			struct sal_entrypoint_descriptor *dp;

			dp = (struct sal_entrypoint_descriptor*)p;
			ia64_pal_entry =
				IA64_PHYS_TO_RR7(dp->sale_pal_proc);
			PRINT_BV("  PAL Proc at 0x%lx\n", ia64_pal_entry);
			sal_fdesc.func =
				IA64_PHYS_TO_RR7(dp->sale_sal_proc);
			sal_fdesc.gp = IA64_PHYS_TO_RR7(dp->sale_sal_gp);
			PRINT_BV("  SAL Proc at 0x%lx, GP at 0x%lx\n",
				 sal_fdesc.func, sal_fdesc.gp);
			ia64_sal_entry = (sal_entry_t *) &sal_fdesc;
			break;
		}
		default:
			break;
		}
		p += sizes[*p];
	}
}

