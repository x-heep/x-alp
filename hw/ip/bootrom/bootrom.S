// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>
// Paul Scheffler <paulsc@iis.ee.ethz.ch>

// TODO: Avoid hardcoding in addresses and offsets

#include "core_v_mcu.h"
#include "soc_ctrl_regs.h"

#define SOC_CTRL_START_ADDRESS_20bit (SOC_CTRL_START_ADDRESS >> 12)

.section .text._start

// Minimal bootrom loader
.global _start
.align 4
_start:
    // Reset all integer GPRs; we do *not* assume FP in the boot ROM.
    li x1, 0
    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 0
    li x8, 0
    li x9, 0
    li x10, 0
    li x11, 0
    li x12, 0
    li x13, 0
    li x14, 0
    li x15, 0
    li x16, 0
    li x17, 0
    li x18, 0
    li x19, 0
    li x20, 0
    li x21, 0
    li x22, 0
    li x23, 0
    li x24, 0
    li x25, 0
    li x26, 0
    li x27, 0
    li x28, 0
    li x29, 0
    li x30, 0
    li x31, 0

// Reset regs, full fence, then jump to main
_boot:
    li t0, 0
    li t1, 0
    fence
    fence.i
    call main

// If main returns, we end up here
.global _exit
.align 4
_exit:
    // Save the return value to scratch register 2, try `ebreak`, then wait forever
    slli a0, a0, 1
    ori  a0, a0, 1
    lui  a1, SOC_CTRL_START_ADDRESS_20bit
    sw   a0, SOC_CTRL_EXIT_VALUE_REG_OFFSET(a1)
    ebreak
1:  wfi
    j 1b

.global boot_next_stage
.align 4
boot_next_stage:
    // Load boot address from global scratch registers
    jalr ra, 0(a0)
    // We should never get here
    ret
