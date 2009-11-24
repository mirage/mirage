/*
(C) Copyright IBM Corp. 2006

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
    * Neither the name of IBM nor the names of its contributors may be
used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Author: Joel Schopp <jschopp@austin.ibm.com>
*/

#ifndef __ASSEMBLER__
#include <errno.h>
#include <sys/syscall.h>
#endif /* !__ASSEMBLER__ */

#define SPE_C99_SIGNALCODE 0x2100

#define SPE_C99_OP_SHIFT    	24
#define SPE_C99_OP_MASK	    	0xff
#define SPE_C99_DATA_MASK   	0xffffff

#define SPE_C99_CLEARERR    1
#define SPE_C99_FCLOSE      2
#define SPE_C99_FEOF        3
#define SPE_C99_FERROR      4
#define SPE_C99_FFLUSH      5
#define SPE_C99_FGETC       6
#define SPE_C99_FGETPOS     7
#define SPE_C99_FGETS       8
#define SPE_C99_FILENO      9
#define SPE_C99_FOPEN       10 //implemented
#define SPE_C99_FPUTC       11
#define SPE_C99_FPUTS       12
#define SPE_C99_FREAD       13
#define SPE_C99_FREOPEN     14
#define SPE_C99_FSEEK       15
#define SPE_C99_FSETPOS     16
#define SPE_C99_FTELL       17
#define SPE_C99_FWRITE      18
#define SPE_C99_GETC        19
#define SPE_C99_GETCHAR     20
#define SPE_C99_GETS        21
#define SPE_C99_PERROR      22
#define SPE_C99_PUTC        23
#define SPE_C99_PUTCHAR     24
#define SPE_C99_PUTS        25
#define SPE_C99_REMOVE      26
#define SPE_C99_RENAME      27
#define SPE_C99_REWIND      28
#define SPE_C99_SETBUF      29
#define SPE_C99_SETVBUF     30
#define SPE_C99_SYSTEM      31 //not yet implemented in newlib
#define SPE_C99_TMPFILE     32
#define SPE_C99_TMPNAM      33
#define SPE_C99_UNGETC      34
#define SPE_C99_VFPRINTF    35
#define SPE_C99_VFSCANF     36
#define SPE_C99_VPRINTF     37
#define SPE_C99_VSCANF      38
#define SPE_C99_VSNPRINTF   39
#define SPE_C99_VSPRINTF    40
#define SPE_C99_VSSCANF     41
#define SPE_C99_LAST_OPCODE 42

#define SPE_C99_NR_OPCODES 	((SPE_C99_LAST_OPCODE - SPE_C99_CLEARERR) + 1)

#define SPE_STDIN                   1
#define SPE_STDOUT                  2
#define SPE_STDERR                  3
#define SPE_FOPEN_MAX               FOPEN_MAX

#ifdef __ASSEMBLER__
#define SPE_STACK_REGS      72 /* Number of registers preserved in stack
                                  in case of variable argument API. */
#else /* !__ASSEMBLER__ */
struct spe_reg128{
  unsigned int slot[4];
};

void _EXFUN(__sinit,(struct _reent *));
FILE  *_EXFUN(__sfp,(struct _reent *));
#define __sfp_free(fp) ( (fp)->_fp = 0 )

#define CHECK_INIT(ptr) \
  do { if ((ptr) && !(ptr)->__sdidinit) __sinit (ptr); } while (0)
#define CHECK_STD_INIT(ptr) /* currently, do nothing */
#define CHECK_STR_INIT(ptr) /* currently, do nothing */
#endif /* __ASSEMBLER__ */
