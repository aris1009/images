/*
 * squid-probe - liveness check for the squid-hardened image.
 *
 * The runtime image has no shell, so a health check cannot be a shell command.
 * This binary opens a TCP connection to the proxy, sends one minimal HTTP
 * request, and exits 0 when the proxy answers with anything at all (typically
 * 403 or 503 under a deny-by-default policy). A connection that is accepted but
 * never answered is treated as unhealthy.
 *
 * The request targets 127.0.0.1:80 so that a permissive configuration cannot
 * make the proxy dial itself; the proxy's own response is enough.
 *
 * Port defaults to 3128 and can be overridden with SQUID_PROBE_PORT for images
 * or deployments that change http_port.
 *
 * Built statically in the builder stage; no libc is installed in the runtime.
 */
#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <unistd.h>

static const char request[] =
    "GET http://127.0.0.1/ HTTP/1.0\r\n"
    "Host: 127.0.0.1\r\n"
    "User-Agent: squid-probe\r\n"
    "\r\n";

int main(void)
{
    const char *env_port = getenv("SQUID_PROBE_PORT");
    long port = 3128;

    if (env_port != NULL && *env_port != '\0') {
        char *end = NULL;
        port = strtol(env_port, &end, 10);
        if (end == env_port || *end != '\0' || port < 1 || port > 65535)
            return 1;
    }

    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0)
        return 1;

    struct timeval timeout;
    timeout.tv_sec = 3;
    timeout.tv_usec = 0;
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof timeout);
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof timeout);

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof addr);
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short)port);
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);

    if (connect(fd, (struct sockaddr *)&addr, sizeof addr) != 0) {
        close(fd);
        return 1;
    }

    if (send(fd, request, sizeof request - 1, 0) <= 0) {
        close(fd);
        return 1;
    }

    char reply[64];
    ssize_t got = recv(fd, reply, sizeof reply, 0);
    close(fd);

    return got > 0 ? 0 : 1;
}
