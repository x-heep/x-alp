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
#include "axi_llc_regs.h"

#define SOC_CTRL_START_ADDRESS_20bit (SOC_CTRL_BASE_ADDRESS >> 12)

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
    // loop until SOC_CTRL_START_ADDRESS, SOC_CTRL_BOOT_EXIT_LOOP_REG_OFFSET is not 0
    lui  a1, SOC_CTRL_START_ADDRESS_20bit
_boot_wait_loop:
    lw t0, SOC_CTRL_BOOT_EXIT_LOOP_REG_OFFSET(a1)
    bne t0, zero, _boot_continue
    j _boot_wait_loop
_boot_continue:
    fence
    // lwu, not lw: this is RV64 and a boot address with bit 31 set (e.g. DRAM
    // at 0x80000000) would sign-extend into 0xFFFFFFFF80000000.
    lwu a0, SOC_CTRL_BOOT_ADDRESS_REG_OFFSET(a1)

    // Booting out of the LLC scratchpad? Then every way has to be locked as SPM
    // before the first fetch: the LLC answers an SPM access to a way still
    // configured as cache with SLVERR, and out of reset no way is locked. This
    // has to happen here, in the boot ROM, because the payload cannot configure
    // the memory it is itself being fetched from.
    li   t1, LLC_START_ADDRESS
    bltu a0, t1, _boot_jump
    li   t2, LLC_END_ADDRESS
    bgeu a0, t2, _boot_jump
    li   t1, AXI_LLC_BASE_ADDRESS
    // Out of reset the LLC runs a BIST over its tag storage and writes the
    // result into CFG_SPM when it finishes. Configuring before that point is
    // silently undone, so wait for the done flag first.
_boot_wait_bist:
    lw   t2, AXI_LLC_BIST_STATUS_REG_OFFSET(t1)
    andi t2, t2, (1 << AXI_LLC_BIST_STATUS_DONE_BIT)
    beqz t2, _boot_wait_bist

    li   t2, -1
    sw   t2, AXI_LLC_CFG_SPM_LOW_REG_OFFSET(t1)
    sw   t2, AXI_LLC_CFG_SPM_HIGH_REG_OFFSET(t1)
    li   t2, 1
    sw   t2, AXI_LLC_COMMIT_CFG_REG_OFFSET(t1)
    // Wait for the commit to land before fetching from the SPM: while the LLC
    // applies a new configuration it isolates its slave port, so a fetch issued
    // now would race the flush. Read CFG_SPM back rather than comparing against
    // all-ones: only SetAssociativity bits of it are implemented.
    lw   t0, AXI_LLC_CFG_SPM_LOW_REG_OFFSET(t1)
_boot_wait_spm:
    lw   t2, AXI_LLC_FLUSHED_LOW_REG_OFFSET(t1)
    bne  t2, t0, _boot_wait_spm

_boot_jump:
    fence.i
    jalr 0(a0)
    


// If main returns, we end up here
.global _exit
.align 4
_exit:
    // Publish the return value, raise the exit flag, then wait forever. The
    // testbench polls EXIT_VALID; soc_ctrl keeps value and flag in separate
    // registers, so both have to be written (value first).
    lui  a1, SOC_CTRL_START_ADDRESS_20bit
    sw   a0, SOC_CTRL_EXIT_VALUE_REG_OFFSET(a1)
    li   a0, 1
    sw   a0, SOC_CTRL_EXIT_VALID_REG_OFFSET(a1)
1:  wfi
    j 1b

.global boot_next_stage
.align 4
boot_next_stage:
    // Load boot address from global scratch registers
    jalr ra, 0(a0)
    // We should never get here
    ret
