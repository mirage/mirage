#ifndef __CUSTOM_FILE_H__
#define __CUSTOM_FILE_H__ 1

/*
 * Cell SPE support
 */
struct __sFILE_spu {
  int _fp; /* pseudo FILE pointer on PPE */
};
typedef struct __sFILE_spu __FILE;

#endif /* __CUSTOM_FILE_H__ */

