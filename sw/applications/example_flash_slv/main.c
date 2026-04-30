#include "core_v_mcu.h"
#include "printf.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

int32_t A[16] = {0x00000000, 
                 0x00000001,
                 0x00000012,
                 0x00000123,
                 0x00001234,
                 0x00012345,
                 0x00123456,
                 0x01234567,
                 0x12345678,
                 0x23456789,
                 0x3456789A,
                 0x456789AB,
                 0x56789ABC,
                 0x6789ABCD,
                 0x789ABCDE, 
                 0x89ABCDEF};


int64_t B[16];

int main(int argc, char *argv[]) {

  /* write something to the external slave interface */

  volatile int8_t *external_slave_address = (int8_t *)FLASH_STORAGE_BASE_ADDR;

  for (int i = 0; i < 16*4; i++) {
    external_slave_address[i] = (int8_t)( A[i / 4] >> ((i % 4)*8) );
  }

  /* read it back */

  for (int i = 0; i < 16; i ++) {
    B[i] = 0;
    for(int k = 0; k < 4; k++) {
      B[i] |= external_slave_address[i*4+k] << (k*8);
    }
  }

  /* check results */

  for (int i = 0; i < 16; i++) {
    if (A[i] != B[i]) {
      printf("[%d] w %d, r %d\n", i, A[i], B[i]);
      return EXIT_FAILURE;
    }
  }

  return EXIT_SUCCESS;
}