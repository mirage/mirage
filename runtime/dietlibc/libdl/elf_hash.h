static unsigned int elf_hash(const unsigned char *name) {
  unsigned int h=0, g;

  while (*name) {
    h = (h<<4) + *(name++);
    if ((g = h&0xf0000000)) h ^= g>>24;
    h ^= g;
  }
  return h;
}
