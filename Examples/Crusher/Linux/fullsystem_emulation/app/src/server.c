#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <netdb.h>
#include <arpa/inet.h>

#define BUFSIZE 1024
#define PORT 8080

const int DETECT = 0xBEEFDEAD;

int main(void)
{
    int serverfd; 
    int clientfd; 
    struct sockaddr_in serveraddr; 
    struct sockaddr_in clientaddr;

    unsigned int n;
    char buf[BUFSIZE];

    serverfd = socket(AF_INET, SOCK_STREAM, 0);
    if (serverfd < 0) {
        puts("ERROR opening socket");
        return 1;
    }

    int optval = 1;
    setsockopt(serverfd, SOL_SOCKET, SO_REUSEADDR, (const void *)&optval , sizeof(int));

    memset((char *) &serveraddr, 0, sizeof(serveraddr));
    serveraddr.sin_family = AF_INET;
    serveraddr.sin_addr.s_addr = inet_addr("127.0.0.1");
    serveraddr.sin_port = htons(PORT);

    if (bind(serverfd, (struct sockaddr *) &serveraddr, sizeof(serveraddr)) < 0) {
        puts("ERROR on binding");
        return 1;
    }

    if (listen(serverfd, 5) < 0) {
        puts("ERROR on listen");
        return 1;
    } 

    while (1) {
        socklen_t clientlen = sizeof(clientaddr);
        clientfd = accept(serverfd, (struct sockaddr *) &clientaddr, &clientlen);
        if (clientfd < 0) {
            puts("ERROR on accept");
            return 1;
        } 
    
        memset(buf, 0, BUFSIZE);
        n = read(clientfd, buf, BUFSIZE);
        if (n < 0) {
            puts("ERROR reading from socket");
            return 1;
        } 

        if (buf[0] % 3 == 0) {
            puts("Crash");
            return 1;
        } else if (buf[0] % 3 == 1) {
            puts("Hello");
        } else {
            puts("Bye");
        }

        printf("Server received %d bytes: %s", n, buf);
    
        n = write(clientfd, buf, strlen(buf));
        if (n < 0) {
            puts("ERROR writing to socket");
            return 1;
        } 

        close(clientfd);

        break;
    }

    close(serverfd);

    return 0;
}
