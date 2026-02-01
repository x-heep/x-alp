#include "printf.h"
#include "core_v_mcu.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int32_t A [16] = {
    0, 1, 2, 3,
    4, 5, 6, 7,
    8, 9,10,11,
   12,13,14,15
};

int64_t B [16];

int main(int argc, char *argv[]) {

    /* write something to the external slave interface */

    volatile int64_t *external_slave_address = (int64_t *) EXT_S_BUS_BASE_ADDR;

    for (int i = 0; i < 16; i+=2) {
        external_slave_address[i/2] = ((int64_t)A[i] << 32) | (int64_t)A[i+1];
    }

    /* read it back */

    for (int i = 0; i < 16; i+=2) {
        int64_t val = external_slave_address[i/2];
        B[i]   = (val >> 32) & 0xFFFFFFFF;
        B[i+1] = val & 0xFFFFFFFF;
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