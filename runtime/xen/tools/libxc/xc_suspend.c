/*
 * This file is subject to the terms and conditions of the GNU General
 * Public License.  See the file "COPYING" in the main directory of
 * this archive for more details.
 */

#include "xc_private.h"
#include "xenguest.h"

#define SUSPEND_LOCK_FILE "/var/lib/xen/suspend_evtchn_lock.d"
static int lock_suspend_event(void)
{
    int fd, rc;
    mode_t mask;
    char buf[128];

    mask = umask(022);
    fd = open(SUSPEND_LOCK_FILE, O_CREAT | O_EXCL | O_RDWR, 0666);
    if (fd < 0)
    {
        ERROR("Can't create lock file for suspend event channel\n");
        return -EINVAL;
    }
    umask(mask);
    snprintf(buf, sizeof(buf), "%10ld", (long)getpid());

    rc = write_exact(fd, buf, strlen(buf));
    close(fd);

    return rc;
}

static int unlock_suspend_event(void)
{
    int fd, pid, n;
    char buf[128];

    fd = open(SUSPEND_LOCK_FILE, O_RDWR);

    if (fd < 0)
        return -EINVAL;

    n = read(fd, buf, 127);

    close(fd);

    if (n > 0)
    {
        sscanf(buf, "%d", &pid);
        /* We are the owner, so we can simply delete the file */
        if (pid == getpid())
        {
            unlink(SUSPEND_LOCK_FILE);
            return 0;
        }
    }

    return -EPERM;
}

int xc_await_suspend(int xce, int suspend_evtchn)
{
    int rc;

    do {
        rc = xc_evtchn_pending(xce);
        if (rc < 0) {
            ERROR("error polling suspend notification channel: %d", rc);
            return -1;
        }
    } while (rc != suspend_evtchn);

    /* harmless for one-off suspend */
    if (xc_evtchn_unmask(xce, suspend_evtchn) < 0)
        ERROR("failed to unmask suspend notification channel: %d", rc);

    return 0;
}

int xc_suspend_evtchn_release(int xce, int suspend_evtchn)
{
    if (suspend_evtchn >= 0)
        xc_evtchn_unbind(xce, suspend_evtchn);

    return unlock_suspend_event();
}

int xc_suspend_evtchn_init(int xc, int xce, int domid, int port)
{
    int rc, suspend_evtchn = -1;

    if (lock_suspend_event())
        return -EINVAL;

    suspend_evtchn = xc_evtchn_bind_interdomain(xce, domid, port);
    if (suspend_evtchn < 0) {
        ERROR("failed to bind suspend event channel: %d", suspend_evtchn);
        goto cleanup;
    }

    rc = xc_domain_subscribe_for_suspend(xc, domid, port);
    if (rc < 0) {
        ERROR("failed to subscribe to domain: %d", rc);
        goto cleanup;
    }

    /* event channel is pending immediately after binding */
    xc_await_suspend(xce, suspend_evtchn);

    return suspend_evtchn;

cleanup:
    if (suspend_evtchn != -1)
        xc_suspend_evtchn_release(xce, suspend_evtchn);

    return -1;
}
