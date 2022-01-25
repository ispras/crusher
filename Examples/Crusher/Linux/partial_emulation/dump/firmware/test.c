#include "header.h"

struct Data {
  int x;
  char *buf;
};

int check_number(int n) {
  int *ptr = NULL;
  if (n > 0 && n < 0x10000000) {
    if (2 * n + 5 == 0x0204060D) {
      *ptr = 123;
    }
  }
  return 1;
}

int function(int arg, struct Data *d) {
  int *p = (int *) d->buf;
  int n = *p;
  if (!check_hardware()) {
    return 0;
  }
  if (!check_number(n)) {
    return 0;
  }
  return 1;
}

void c_entry() {
  struct Data data;
  data.x = 123;
  data.buf = input;
  function(0, &data);
  while(1);
}

