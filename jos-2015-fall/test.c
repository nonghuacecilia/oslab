#include<stdio.h>
int main()
{
  int a = ((unsigned int)0x10000000) >> 12;
  printf("a value is %08x\n", a);
  return 0;
}
