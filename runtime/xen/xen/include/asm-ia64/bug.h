#ifndef __IA64_BUG_H__
#define __IA64_BUG_H__

#define BUG() __bug(__FILE__, __LINE__)
#define WARN() __warn(__FILE__, __LINE__)

#define dump_execution_state()                                      \
    do {                                                            \
        printk("FIXME: implement ia64 dump_execution_state()\n");	\
        dump_stack();                                               \
    } while (0)

#define vcpu_show_execution_state(v) printk("FIXME: implement ia64 vcpu_show_execution_state()\n")

#endif /* __IA64_BUG_H__ */
