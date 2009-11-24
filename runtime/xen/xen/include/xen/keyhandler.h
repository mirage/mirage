/******************************************************************************
 * keyhandler.h
 * 
 * We keep an array of 'handlers' for each key code between 0 and 255;
 * this is intended to allow very simple debugging routines (toggle 
 * debug flag, dump registers, reboot, etc) to be hooked in in a slightly
 * nicer fashion than just editing the serial/keyboard drivers. 
 */

#ifndef __XEN_KEYHANDLER_H__
#define __XEN_KEYHANDLER_H__

typedef void keyhandler_fn_t(
    unsigned char key);
typedef void irq_keyhandler_fn_t(
    unsigned char key, struct cpu_user_regs *regs);

struct keyhandler {
    /*
     * If TRUE then u.irq_fn is called in hardirq context with interrupts
     * disabled. The @regs callback parameter points at the interrupted
     * register context. 
     * If FALSE then u.fn is called in softirq context with no locks held and
     * interrupts enabled.
     */
    bool_t irq_callback;

    /*
     * If TRUE then the keyhandler will be included in the "dump everything"
     * keyhandler, so must not have any side-effects.
     */
    bool_t diagnostic;

    union {
        keyhandler_fn_t *fn;
        irq_keyhandler_fn_t *irq_fn;
    } u;

    /* The string is not copied by register_keyhandler(), so must persist. */
    char *desc;
};

/* Initialize keytable with default handlers */
extern void initialize_keytable(void);

/*
 * Register a callback handler for key @key. The keyhandler structure is not
 * copied, so must persist.
 */
extern void register_keyhandler(unsigned char key, struct keyhandler *handler);

/* Inject a keypress into the key-handling subsystem. */
extern void handle_keypress(unsigned char key, struct cpu_user_regs *regs);

#endif /* __XEN_KEYHANDLER_H__ */
