// Copyright 2022 EPFL and Politecnico di Torino.
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// File: obi.hh
// Author: Michele Caon
// Date: 15/02/2023
// Description: OBI definitions

#ifndef OBI_HH_
#define OBI_HH_

#include <stdint.h>

typedef struct {
    uint8_t req;
    uint8_t we;
    uint8_t be;
    uint32_t addr;
    uint32_t wdata;
} obi_req_t;

typedef struct {
    uint8_t gnt;
    uint8_t rvalid;
    uint32_t rdata;
} obi_rsp_t;

#endif /* OBI_HH_ */
