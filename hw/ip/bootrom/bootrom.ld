/* Copyright 2022 ETH Zurich and University of Bologna. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/* Nicole Narr <narrn@student.ethz.ch> */
/* Christopher Reinwardt <creinwar@student.ethz.ch> */
/* Paul Scheffler <paulsc@iis.ee.ethz.ch> */

OUTPUT_ARCH( "riscv" )
ENTRY( _start )
SECTIONS
{
    . = 0x000;
  .text : {
    *(.text._start)
    *(.text)
    *(.text.*)
  }
    _end = .;
}
