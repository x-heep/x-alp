// Copyright 2022 OpenHW Group
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1


#ifndef _COREV_MCU_H_
#define _COREV_MCU_H_

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

#define MEMORY_BANKS 1

% for a_slave in xalp.bus().get_slaves():
#define ${a_slave.name.upper()}_START_ADDRESS 0x${f"{a_slave.start_address:016X}"}
#define ${a_slave.name.upper()}_SIZE 0x${f"{a_slave.length:016X}"}
#define ${a_slave.name.upper()}_END_ADDRESS (${a_slave.name.upper()}_START_ADDRESS + ${a_slave.name.upper()}_SIZE)

% endfor

% for a_peripheral in xalp.get_peripheral_domain("Peripherals").get_peripherals():
#define ${a_peripheral._name.upper()}_BASE_ADDRESS (PERIPHERALS_START_ADDRESS +  0x${f"{a_peripheral.get_address():016X}"})
#define ${a_peripheral._name.upper()}_SIZE 0x${f"{a_peripheral.get_length():016X}"}
#define ${a_peripheral._name.upper()}_END_ADDRESS (${a_peripheral._name.upper()}_BASE_ADDRESS + ${a_peripheral._name.upper()}_SIZE)

% endfor

// Parametrize it with object DMA once the py object XAlp gets developed
#define DMA_CH_NUM 1
#define DMA_CH_SIZE 0x100
#define DMA_NUM_MASTER_PORTS 1
#define DMA_ADDR_MODE 1
#define DMA_SUBADDR_MODE 1  
#define DMA_HW_FIFO_MODE 0
#define DMA_ZERO_PADDING 1

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus

#endif // _COREV_MCU_H_
