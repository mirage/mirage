#ifndef __XEN_PERFC_H__
#define __XEN_PERFC_H__

#ifdef PERF_COUNTERS

#include <xen/lib.h>
#include <xen/smp.h>
#include <xen/percpu.h>

/*
 * NOTE: new counters must be defined in perfc_defn.h
 * 
 * Counter declarations:
 * PERFCOUNTER (counter, string)              define a new performance counter
 * PERFCOUNTER_ARRAY (counter, string, size)  define an array of counters
 * 
 * Unlike counters, status variables do not reset:
 * PERFSTATUS (counter, string)               define a new performance stauts
 * PERFSTATUS_ARRAY (counter, string, size)   define an array of status vars
 * 
 * unsigned long perfc_value  (counter)        get value of a counter  
 * unsigned long perfc_valuea (counter, index) get value of an array counter
 * unsigned long perfc_set  (counter, val)     set value of a counter  
 * unsigned long perfc_seta (counter, index, val) set value of an array counter
 * void perfc_incr  (counter)                  increment a counter          
 * void perfc_decr  (counter)                  decrement a status
 * void perfc_incra (counter, index)           increment an array counter   
 * void perfc_add   (counter, value)           add a value to a counter     
 * void perfc_adda  (counter, index, value)    add a value to array counter 
 * void perfc_print (counter)                  print out the counter
 */

#define PERFCOUNTER( name, descr ) \
  PERFC_##name,
#define PERFCOUNTER_ARRAY( name, descr, size ) \
  PERFC_##name,                                \
  PERFC_LAST_##name = PERFC_ ## name + (size) - sizeof(char[2 * !!(size) - 1]),

#define PERFSTATUS       PERFCOUNTER
#define PERFSTATUS_ARRAY PERFCOUNTER_ARRAY

enum perfcounter {
#include <xen/perfc_defn.h>
	NUM_PERFCOUNTERS
};

#undef PERFCOUNTER
#undef PERFCOUNTER_ARRAY
#undef PERFSTATUS
#undef PERFSTATUS_ARRAY

typedef unsigned perfc_t;
#define PRIperfc ""

DECLARE_PER_CPU(perfc_t[NUM_PERFCOUNTERS], perfcounters);

#define perfc_value(x)    this_cpu(perfcounters)[PERFC_ ## x]
#define perfc_valuea(x,y)                                               \
    ( (y) <= PERFC_LAST_ ## x - PERFC_ ## x ?                           \
	 this_cpu(perfcounters)[PERFC_ ## x + (y)] : 0 )
#define perfc_set(x,v)    (this_cpu(perfcounters)[PERFC_ ## x] = (v))
#define perfc_seta(x,y,v)                                               \
    ( (y) <= PERFC_LAST_ ## x - PERFC_ ## x ?                           \
	 this_cpu(perfcounters)[PERFC_ ## x + (y)] = (v) : (v) )
#define perfc_incr(x)     (++this_cpu(perfcounters)[PERFC_ ## x])
#define perfc_decr(x)     (--this_cpu(perfcounters)[PERFC_ ## x])
#define perfc_incra(x,y)                                                \
    ( (y) <= PERFC_LAST_ ## x - PERFC_ ## x ?                           \
	 ++this_cpu(perfcounters)[PERFC_ ## x + (y)] : 0 )
#define perfc_add(x,v)    (this_cpu(perfcounters)[PERFC_ ## x] += (v))
#define perfc_adda(x,y,v)                                               \
    ( (y) <= PERFC_LAST_ ## x - PERFC_ ## x ?                           \
	 this_cpu(perfcounters)[PERFC_ ## x + (y)] = (v) : (v) )

/*
 * Histogram: special treatment for 0 and 1 count. After that equally spaced 
 * with last bucket taking the rest.
 */
#ifdef PERF_ARRAYS
#define perfc_incr_histo(x,v)                                           \
    do {                                                                \
        if ( (v) == 0 )                                                 \
            perfc_incra(x, 0);                                          \
        else if ( (v) == 1 )                                            \
            perfc_incra(x, 1);                                          \
        else if ( (((v) - 2) / PERFC_ ## x ## _BUCKET_SIZE) <           \
                  (PERFC_LAST_ ## x - PERFC_ ## x - 2) )                \
            perfc_incra(x, (((v) - 2) / PERFC_ ## x ## _BUCKET_SIZE) + 2); \
        else                                                            \
            perfc_incra(x, PERFC_LAST_ ## x - PERFC_ ## x);             \
    } while ( 0 )
#else
#define perfc_incr_histo(x,v) ((void)0)
#endif

struct xen_sysctl_perfc_op;
int perfc_control(struct xen_sysctl_perfc_op *);
    
#else /* PERF_COUNTERS */

#define perfc_value(x)    (0)
#define perfc_valuea(x,y) (0)
#define perfc_set(x,v)    ((void)0)
#define perfc_seta(x,y,v) ((void)0)
#define perfc_incr(x)     ((void)0)
#define perfc_decr(x)     ((void)0)
#define perfc_incra(x,y)  ((void)0)
#define perfc_decra(x,y)  ((void)0)
#define perfc_add(x,y)    ((void)0)
#define perfc_adda(x,y,z) ((void)0)
#define perfc_incr_histo(x,y,z) ((void)0)

#endif /* PERF_COUNTERS */

#endif /* __XEN_PERFC_H__ */
