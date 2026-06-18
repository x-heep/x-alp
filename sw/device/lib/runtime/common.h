// Copyright 2025 EPFL and Politecnico di Torino
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Vincenzo Petrolo <vincenzo.petrolo@polito.it>

/**
 * @file common.h
 * @brief Common functions used for initializing x-alp
 */

#pragma once

#include "core_v_mcu.h"
#include "axi_llc_regs.h"
#include "printf.h"
#include "util.h"

typedef enum {
    CVM_COMMON_ENOERR,
    CVM_COMMON_ERR_UART,
    CVM_COMMON_ERR_INT,
} cvm_common_err_t;

/**
 * This function brings up:
 * - UART
 * - INTERRUPTS
 *   It takes no arguments and returns an error indicating which of the sw
 *   modules failed.
 */
cvm_common_err_t
cvm_init(void);
