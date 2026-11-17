#include "core_v_mcu.h"
#include "printf.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>


#define DMA_BASE_ADDRESS 0x0000000020060000
#define DMA_START_ADDRESS DMA_BASE_ADDRESS
#define DMA_SIZE 0x0000000000010000
#define DMA_END_ADDRESS (DMA_BASE_ADDRESS + DMA_SIZE)

int32_t A[16] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};

int64_t B[16];

int main(int argc, char *argv[]) {

  /* write something to the external slave interface */

  volatile int64_t *dma_start_address = (int64_t *)DMA_START_ADDRESS;

  volatile int64_t *external_slave_address = (int64_t *)EXT_SLAVES_START_ADDRESS;

  for (int i = 0; i < 16; i += 2) { external_slave_address[i / 2] = ((int64_t)A[i] << 32) | (int64_t)A[i + 1]; }

  /* read it back */

  for (int i = 0; i < 16; i += 2) {
    int64_t val = external_slave_address[i / 2];
    B[i] = (val >> 32) & 0xFFFFFFFF;
    B[i + 1] = val & 0xFFFFFFFF;
  }

  /* check results */

  for (int i = 0; i < 16; i++) {
    if (A[i] != B[i]) {
      printf("[%d] w %d, r %d\n", i, A[i], B[i]);
      return EXIT_FAILURE;
    }
  }

  printf("Starting DMA Test peripheral:\n");
  printf("DMA Start Address: 0x%lx\n", DMA_START_ADDRESS);
  *dma_start_address = 0x1; // start the DMA transfer
  *dma_start_address = 0x2; // start the DMA transfer
  *dma_start_address = 0x3; // start the DMA transfer

  //Data transfer hangs here.
  printf("Reading back from DMA peripheral:\n");
  printf("Data: 0x%lx\n", *dma_start_address);

  return EXIT_SUCCESS;
}