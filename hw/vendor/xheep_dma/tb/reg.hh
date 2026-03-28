// Copyright 2022 EPFL and Politecnico di Torino.
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// File: reg.hh
// Author: Michele Caon
// Date: 15/02/2023
// Description: Register interface definitions

#ifndef REG_HH_
#define REG_HH_

#include <stdint.h>

typedef struct {
    uint8_t valid;
    uint8_t write;
    uint8_t wstrb;
    uint32_t addr;
    uint32_t wdata;
} reg_req_t;

typedef struct {
    uint8_t error;
    uint8_t ready;
    uint32_t rdata;
} reg_rsp_t;

#endif /* REG_HH_ */
