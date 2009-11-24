/* 
 * daytime.c: a simple network service based on lwIP and mini-os
 * 
 * Tim Deegan <Tim.Deegan@eu.citrix.net>, July 2007
 */

#include <os.h>
#include <xmalloc.h>
#include <console.h>
#include <netfront.h>
#include <lwip/api.h>

static char message[29];

void run_server(void *p)
{
    struct ip_addr listenaddr = { 0 };
    struct netconn *listener;
    struct netconn *session;
    struct timeval tv;
    err_t rc;

    start_networking();

    if (0) {
        struct ip_addr ipaddr = { htonl(0x0a000001) };
        struct ip_addr netmask = { htonl(0xff000000) };
        struct ip_addr gw = { 0 };
        networking_set_addr(&ipaddr, &netmask, &gw);
    }

    tprintk("Opening connection\n");

    listener = netconn_new(NETCONN_TCP);
    tprintk("Connection at %p\n", listener);

    rc = netconn_bind(listener, &listenaddr, 13);
    if (rc != ERR_OK) {
        tprintk("Failed to bind connection: %i\n", rc);
        return;
    }

    rc = netconn_listen(listener);
    if (rc != ERR_OK) {
        tprintk("Failed to listen on connection: %i\n", rc);
        return;
    }

    while (1) {
        session = netconn_accept(listener);
        if (session == NULL) 
            continue;

        gettimeofday(&tv, NULL);
        sprintf(message, "%20lu.%6.6lu\n", tv.tv_sec, tv.tv_usec);
        (void) netconn_write(session, message, strlen(message), NETCONN_COPY);
        (void) netconn_disconnect(session);
        (void) netconn_delete(session);
    }
}


int app_main(start_info_t *si)
{
    create_thread("server", run_server, NULL);
    return 0;
}
