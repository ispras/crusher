#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <fcntl.h>

#include <sys/socket.h>
#include <netdb.h>

#define MAX_PATH_LEN 1024

int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen) {
	printf("accept -> stub\n");

	char *packet_path = getenv("ISP_PRELOAD_CUR_INPUT");

	int fd = open(packet_path, O_RDONLY, 0640);
    return fd;
}

struct hostent *gethostbyaddr(const void *addr, socklen_t len, int type) {
	struct hostent* host = (struct hostent*) malloc(sizeof(struct hostent));
	memset(host, 1, sizeof(host));
	printf("gethostbyaddr -> stub\n");
	return host;
}

char *inet_ntoa(struct in_addr in) {
	char* ip = (char*) malloc(2 * sizeof(char));
	ip[0] = '1';
	ip[1] = '\0';
	printf("inet_ntoa -> stub\n");
	return ip;
}

unsigned int sleep(unsigned int seconds) {
	printf("sleep -> stub\n");
    return 0;
}
