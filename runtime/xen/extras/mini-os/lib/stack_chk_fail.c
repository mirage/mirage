#include <mini-os/kernel.h>
#include <mini-os/console.h>

void __stack_chk_fail(void)
{
    printk("stack smashing detected\n");
    do_exit();
}
