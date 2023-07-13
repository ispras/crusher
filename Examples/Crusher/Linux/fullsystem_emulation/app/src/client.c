#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include <signal.h>

#define BUFSIZE 1024
#define PORT 8080

const int DETECT = 0xDEADBEEF;
char buf[BUFSIZE];

typedef struct flags
{
    int DATA_SEND;
    int DATA_SENT;
    int DATA_RECV;
    int SRV_CRASH;
} flags;

void get_flags(flags *);

int main(int argc, char *argv[])
{
    if (argc < 2) {
        printf("Usage: %s <server PID>", argv[0]);
        return 1;
    }
    int serverpid = atoi(argv[1]);

    int connfd;
    struct sockaddr_in serveraddr;

    unsigned int n;
    flags flag;

    memset(&flag, 0, sizeof(flags));

    connfd = socket(AF_INET, SOCK_STREAM, 0);
    if (connfd < 0) {
        puts("ERROR opening socket");
        return 1;
    }

    memset((char *) &serveraddr, 0, sizeof(serveraddr));
    serveraddr.sin_family = AF_INET;
    serveraddr.sin_addr.s_addr = inet_addr("127.0.0.1");
    serveraddr.sin_port = htons(PORT);

    if (connect(connfd, (struct sockaddr *)&serveraddr, sizeof(serveraddr) ) < 0) {
        puts("ERROR connection with the server");
        return 1;
    }

    printf("DBG Buffer address: %p\n", buf);
    
    while (1) {
        if (flag.DATA_SEND) {
            n = write(connfd, buf, strlen(buf));
            if (n < 0) {
                puts("ERROR writing to socket");
                return 1;
            }
            flag.DATA_SENT = 1;

            memset(buf, 0, BUFSIZE);
            n = read(connfd, buf, BUFSIZE);
            if (n < 0) {
                puts("ERROR reading from socket");
                return 1;
            }
        
            if (n > 0) {
                flag.DATA_RECV = 1;
                printf("Client received %d bytes: %s", n, buf);
            }
        }

        if (kill(serverpid, 0) < 0) {
            puts("Server crash");
            
            flag.SRV_CRASH = 1;
            get_flags(&flag);
            
            return 1;
        }

        get_flags(&flag);
    }

    close(connfd);

    return 0;
}

void get_flags(flags *flag)
{
    ;;
}
