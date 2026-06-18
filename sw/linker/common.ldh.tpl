/* Copyright 2022 ETH Zurich and University of Bologna. */
/* Copyright 2026 Politecnico di Torino. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/* Author: Luigi Giuffrida <luigi.giuffrida@polito.it> */

/* This header defines symbols and rules universal to bare-metal execution */

<%
    axi = [s for s in xalp.bus().get_axi_slaves() if "Peripheral" not in s["name"] and "llc" not in s["name"]]
    reg = xalp.bus().get_reg_slaves()
    max_len = max(len(s["name"]) for s in axi + reg)
%>

ENTRY(_start)

MEMORY {
  bootrom (rx)  : ORIGIN = 0x${f'{next(item for item in xalp.bus().get_reg_slaves() if item["name"] == "bootrom")["base"]:08x}'}, LENGTH = 16K
  /* We assume at least 64 KiB SPM, same minus stack for ROMs. */
  /* If more SPM is available, CRT0 repoints the stack. */
  extrom (rx)   : ORIGIN = 0x00000000, LENGTH = 48K
  spm (rwx)     : ORIGIN = 0x${f'{next(item for item in xalp.bus().get_slaves() if item.get_name() == "llc").get_start_address():08x}'}, LENGTH = 64K
  /* We  assume at least 8 MiB of DRAM (minimum for Linux). */
  dram (rwx)    : ORIGIN = 0x80000000, LENGTH = 1024M
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
