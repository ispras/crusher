#include <stdint.h>

// fork
void custom_fork_server();

// mut
uint64_t mutate_int(uint64_t value, size_t len);
void mutate_buf(void *buf, uint32_t *len);
