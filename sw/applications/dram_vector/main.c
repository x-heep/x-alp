#include "core_v_mcu.h"
#include "printf.h"

#include <stdint.h>
#include <stdlib.h>

/* 4 MiB vector: 16x bigger than the 256 KiB LLC, so every pass streams from external DRAM. */
#define N (1u << 20)

/* Code sits at the DRAM base and the stack at its top (dram.ld); park the vector 16 MiB in. */
#define VEC_OFFSET 0x01000000

int main(int argc, char *argv[]) {
  volatile uint32_t *v = (volatile uint32_t *)(DRAM_START_ADDRESS + VEC_OFFSET);

  printf("dram_vector: %u words (%u KiB) at %x\n", (unsigned)N, (unsigned)(N * 4 / 1024), (unsigned)(uintptr_t)v);

  /* pass 1: init v[i] = i */
  for (uint32_t i = 0; i < N; i++) v[i] = i;

  printf("pass 1 done: init\n");

  /* pass 2: in-place v[i] = 3*v[i] + 1 */
  for (uint32_t i = 0; i < N; i++) v[i] = 3 * v[i] + 1;

  printf("pass 2 done: v[i] = 3*v[i]+1\n");

  /* pass 3: reduce */
  uint64_t sum = 0;
  for (uint32_t i = 0; i < N; i++) sum += v[i];

  printf("pass 3 done: sum hi %x lo %x\n", (unsigned)(sum >> 32), (unsigned)sum);

  /* closed form: 3*N*(N-1)/2 + N */
  uint64_t expected = 3ull * N * (N - 1) / 2 + N;

  if (sum != expected) {
    printf("FAIL: sum hi %x lo %x, expected hi %x lo %x\n", (unsigned)(sum >> 32), (unsigned)sum,
           (unsigned)(expected >> 32), (unsigned)expected);
    return EXIT_FAILURE;
  }

  printf("dram_vector OK\n");
  return EXIT_SUCCESS;
}
