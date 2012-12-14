/* Taken from include/minios/x86/os.h
 *
 * random collection of macros and definition
 */

#ifndef _BARRIER_H_
#define _BARRIER_H_

/* This is a barrier for the compiler only, NOT the processor! */
#define barrier() __asm__ __volatile__("": : :"memory")

#define mb()    __asm__ __volatile__ ("mfence":::"memory")
#define rmb()   __asm__ __volatile__ ("lfence":::"memory")
#define wmb()	__asm__ __volatile__ ("sfence" ::: "memory") /* From CONFIG_UNORDERED_IO (linux) */

#endif /* _BARRIER_H_ */
