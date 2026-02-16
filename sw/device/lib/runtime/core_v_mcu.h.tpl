// Copyright 2022 OpenHW Group
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

#ifndef _COREV_MCU_H_
#define _COREV_MCU_H_

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

#define MEMORY_BANKS 1

% for a_slave in xalp.bus.slaves:
#define ${a_slave.name.upper()}_START_ADDRESS ${a_slave.get_start_address()}
#define ${a_slave.name.upper()}_SIZE ${a_slave.get_length()}
#define ${a_slave.name.upper()}_END_ADDRESS (${a_slave.name.upper()}_START_ADDRESS + ${a_slave.name.upper()}_SIZE)

% endfor

% for a_peripheral in xalp.get_peripheral_domain("peripherals").get_peripherals():
#define ${a_peripheral._name.upper()}_BASE_ADDRESS (PERIPHERALS_START_ADDRESS +  0x${f"{a_peripheral.get_address():016x}"})
#define ${a_peripheral._name.upper()}_SIZE 0x${f"{a_peripheral.get_length():016x}"}
#define ${a_peripheral._name.upper()}_END_ADDRESS (${a_peripheral._name.upper()}_BASE_ADDRESS + ${a_peripheral._name.upper()}_SIZE)

% endfor

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus

#endif // _COREV_MCU_H_
