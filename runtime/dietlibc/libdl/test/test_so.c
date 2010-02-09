
int* test();

int err
=(int)test
;

int* test() {
  write(1,"helo\n",5);
  return &err;
}
