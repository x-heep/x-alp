/* Copyright 2022 ETH Zurich and University of Bologna. */
/* Copyright 2026 Politecnico di Torino. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/* Author: Luigi Giuffrida <luigi.giuffrida@polito.it> */

/* This header defines symbols and rules universal to bare-metal execution */

<%
    rules = xalp.bus().get_axi_addr_rules()
    # "spm" and "dram" get their own MEMORY regions below, so they are dropped
    # from the flat __base_* list to avoid defining the same symbol twice.
    axi = [s for s in rules if "Peripheral" not in s["name"] and s["name"] not in ("llc", "dram")]
    reg = xalp.bus().get_reg_slaves()
    spm = next(s for s in rules if s["name"] == "llc")
    dram = next(s for s in rules if s["name"] == "dram")
    bootrom = next(r for r in reg if r["name"] == "bootrom")
    max_len = max(len(s["name"]) for s in axi + reg)
%>

ENTRY(_start)

MEMORY {
  bootrom (rx)  : ORIGIN = 0x${f'{bootrom["base"]:08x}'}, LENGTH = 16K
  /* If more SPM is available, CRT0 repoints the stack. */
  extrom (rx)   : ORIGIN = 0x00000000, LENGTH = 48K
  spm (rwx)     : ORIGIN = 0x${f'{spm["base"]:08x}'}, LENGTH = ${spm["size"] // 1024}K
  dram (rwx)    : ORIGIN = 0x${f'{dram["base"]:08x}'}, LENGTH = ${dram["size"] // 1024}K
}

SECTIONS {
  /* Keep binaries lean */
  /DISCARD/ : { *(.riscv.attributes) *(.comment) }

  /* Global and stack pointer */
  /* By default, keep the calling context (boot ROM) stack pointer */
  __global_pointer$ = ADDR(.misc) + SIZEOF(.misc) / 2;
  __stack_pointer$  = 0;

  /* Further addresses */
% for s in axi:
  __base_${s["name"].ljust(max_len)} = 0x${f'{s["base"]:08X}'};
% endfor
% for r in reg:
  __base_${r["name"].ljust(max_len)} = 0x${f'{r["base"]:08X}'};
% endfor
  __base_${"spm".ljust(max_len)} = ORIGIN(spm);
  __base_${"dram".ljust(max_len)} = ORIGIN(dram);
}
