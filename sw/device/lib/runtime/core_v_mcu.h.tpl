// Copyright 2022 OpenHW Group
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

#ifndef _COREV_MCU_H_
#define _COREV_MCU_H_

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

#define MEMORY_BANKS 1

// AXI slave windows. Primary macro is <NAME>_START_ADDRESS; <NAME>_BASE_ADDRESS
// is provided as an alias so firmware can use either name.
% for s in xalp.bus().get_axi_addr_rules():
#define ${s["macro"]}_START_ADDRESS 0x${f'{s["base"]:016X}'}
#define ${s["macro"]}_BASE_ADDRESS ${s["macro"]}_START_ADDRESS
#define ${s["macro"]}_SIZE 0x${f'{s["size"]:016X}'}
#define ${s["macro"]}_END_ADDRESS (${s["macro"]}_START_ADDRESS + ${s["macro"]}_SIZE)

% endfor

// Register-interface slaves. Primary macro is <NAME>_BASE_ADDRESS;
// <NAME>_START_ADDRESS is provided as an alias so firmware can use either name.
% for r in xalp.bus().get_reg_slaves():
#define ${r["macro"]}_BASE_ADDRESS 0x${f'{r["base"]:016X}'}
#define ${r["macro"]}_START_ADDRESS ${r["macro"]}_BASE_ADDRESS
#define ${r["macro"]}_SIZE 0x${f'{r["size"]:016X}'}
#define ${r["macro"]}_END_ADDRESS (${r["macro"]}_BASE_ADDRESS + ${r["macro"]}_SIZE)

% endfor
<%
    base_axi = [s for s in xalp.bus().get_axi_addr_rules() if "Peripheral" not in s["name"] and s["name"] not in ("llc", "dram")]
    base_reg = xalp.bus().get_reg_slaves()
%>
// Linker-defined base address symbols (from common.ldh). The *address* of each
// symbol is the corresponding base address; use as &__base_<name>.
#ifndef __ASSEMBLER__
% for s in base_axi:
extern char __base_${s["name"]};
% endfor
% for r in base_reg:
extern char __base_${r["name"]};
% endfor
extern char __base_spm;
extern char __base_dram;
#endif // __ASSEMBLER__

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus

#endif // _COREV_MCU_H_
