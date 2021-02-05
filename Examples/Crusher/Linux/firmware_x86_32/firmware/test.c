
void f(void) {
  return;
}

void func(char *input) {
  int *ptr = 0x41414141;
  if (input[0] % 3 == 1) {
    *ptr = 1;
  }
  if (input[0] % 3 == 2) {
    *ptr = 2;
  }
}

void entry()
{
  func(0x20002000);
  while(1);
}

